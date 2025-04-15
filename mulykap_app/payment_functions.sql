-- 1. Fonction pour traiter un nouveau paiement
CREATE OR REPLACE FUNCTION process_payment(
  p_reservation_id UUID,
  p_amount DOUBLE PRECISION,
  p_method payment_method,
  p_transaction_reference TEXT DEFAULT NULL
) RETURNS UUID LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_payment_id UUID;
  v_user_id UUID;
BEGIN
  -- Vérifier si la réservation existe
  IF NOT EXISTS (SELECT 1 FROM reservations WHERE id = p_reservation_id) THEN
    RAISE EXCEPTION 'Réservation non trouvée: %', p_reservation_id;
  END IF;
  
  -- Récupérer l'ID de l'utilisateur pour la notification
  SELECT user_id INTO v_user_id FROM reservations WHERE id = p_reservation_id;
  
  -- Insérer le nouveau paiement
  INSERT INTO payments (
    id,
    reservation_id,
    amount,
    method,
    status,
    transaction_reference,
    created_at
  ) VALUES (
    gen_random_uuid(),
    p_reservation_id,
    p_amount,
    p_method,
    'pending'::payment_status,
    p_transaction_reference,
    now()
  ) RETURNING id INTO v_payment_id;
  
  -- Créer une notification pour l'utilisateur
  INSERT INTO user_notifications (
    id,
    user_id,
    title,
    message,
    notification_type,
    related_entity_id,
    related_entity_type,
    status,
    is_push_sent,
    is_email_sent,
    is_sms_sent,
    send_push,
    send_email,
    send_sms,
    created_at
  ) VALUES (
    gen_random_uuid(),
    v_user_id,
    'Paiement initié',
    'Un paiement de ' || p_amount || ' a été initié pour votre réservation.',
    'paiement_confirmation'::notification_type,
    v_payment_id,
    'payment',
    'non_lue'::notification_status,
    false,
    false,
    false,
    true,
    true,
    false,
    now()
  );
  
  RETURN v_payment_id;
END;
$$;

-- 2. Fonction pour mettre à jour le statut d'un paiement
CREATE OR REPLACE FUNCTION update_payment_status(
  p_payment_id UUID,
  p_status payment_status,
  p_transaction_reference TEXT DEFAULT NULL
) RETURNS VOID LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_reservation_id UUID;
  v_user_id UUID;
  v_old_status payment_status;
  v_notification_type notification_type;
  v_notification_title TEXT;
  v_notification_message TEXT;
BEGIN
  -- Vérifier si le paiement existe
  IF NOT EXISTS (SELECT 1 FROM payments WHERE id = p_payment_id) THEN
    RAISE EXCEPTION 'Paiement non trouvé: %', p_payment_id;
  END IF;
  
  -- Récupérer le statut actuel et la réservation
  SELECT status, reservation_id INTO v_old_status, v_reservation_id FROM payments WHERE id = p_payment_id;
  
  -- Ne rien faire si le statut n'a pas changé
  IF v_old_status = p_status THEN
    RETURN;
  END IF;
  
  -- Récupérer l'utilisateur
  SELECT user_id INTO v_user_id FROM reservations WHERE id = v_reservation_id;
  
  -- Mettre à jour le paiement
  UPDATE payments 
  SET 
    status = p_status,
    transaction_reference = COALESCE(p_transaction_reference, transaction_reference)
  WHERE id = p_payment_id;
  
  -- Configurer la notification en fonction du statut
  CASE p_status
    WHEN 'completed'::payment_status THEN
      v_notification_type := 'paiement_confirmation'::notification_type;
      v_notification_title := 'Paiement confirmé';
      v_notification_message := 'Votre paiement a été confirmé avec succès.';
    WHEN 'failed'::payment_status THEN
      v_notification_type := 'paiement_echec'::notification_type;
      v_notification_title := 'Échec du paiement';
      v_notification_message := 'Votre paiement a échoué. Veuillez réessayer.';
    WHEN 'refunded'::payment_status THEN
      v_notification_type := 'paiement_confirmation'::notification_type;
      v_notification_title := 'Paiement remboursé';
      v_notification_message := 'Votre paiement a été remboursé.';
    ELSE
      v_notification_type := 'paiement_confirmation'::notification_type;
      v_notification_title := 'Mise à jour du paiement';
      v_notification_message := 'Le statut de votre paiement a été mis à jour.';
  END CASE;
  
  -- Créer une notification pour l'utilisateur
  INSERT INTO user_notifications (
    id,
    user_id,
    title,
    message,
    notification_type,
    related_entity_id,
    related_entity_type,
    status,
    is_push_sent,
    is_email_sent,
    is_sms_sent,
    send_push,
    send_email,
    send_sms,
    created_at
  ) VALUES (
    gen_random_uuid(),
    v_user_id,
    v_notification_title,
    v_notification_message,
    v_notification_type,
    p_payment_id,
    'payment',
    'non_lue'::notification_status,
    false,
    false,
    false,
    true,
    true,
    true,
    now()
  );
END;
$$;

-- 3. Trigger pour envoyer une notification lors d'un changement de statut de paiement
CREATE OR REPLACE FUNCTION payment_status_notification()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_user_id UUID;
  v_notification_type notification_type;
  v_notification_title TEXT;
  v_notification_message TEXT;
BEGIN
  -- Ne rien faire si le statut n'a pas changé
  IF NEW.status = OLD.status THEN
    RETURN NEW;
  END IF;
  
  -- Récupérer l'utilisateur associé à la réservation
  SELECT user_id INTO v_user_id 
  FROM reservations 
  WHERE id = NEW.reservation_id;
  
  -- Configurer la notification en fonction du statut
  CASE NEW.status
    WHEN 'completed'::payment_status THEN
      v_notification_type := 'paiement_confirmation'::notification_type;
      v_notification_title := 'Paiement confirmé';
      v_notification_message := 'Votre paiement de ' || NEW.amount || ' a été confirmé avec succès.';
    WHEN 'failed'::payment_status THEN
      v_notification_type := 'paiement_echec'::notification_type;
      v_notification_title := 'Échec du paiement';
      v_notification_message := 'Votre paiement de ' || NEW.amount || ' a échoué. Veuillez réessayer.';
    WHEN 'refunded'::payment_status THEN
      v_notification_type := 'paiement_confirmation'::notification_type;
      v_notification_title := 'Paiement remboursé';
      v_notification_message := 'Votre paiement de ' || NEW.amount || ' a été remboursé.';
    ELSE
      v_notification_type := 'paiement_confirmation'::notification_type;
      v_notification_title := 'Mise à jour du paiement';
      v_notification_message := 'Le statut de votre paiement de ' || NEW.amount || ' a été mis à jour.';
  END CASE;
  
  -- Créer une notification pour l'utilisateur
  INSERT INTO user_notifications (
    id,
    user_id,
    title,
    message,
    notification_type,
    related_entity_id,
    related_entity_type,
    status,
    is_push_sent,
    is_email_sent,
    is_sms_sent,
    send_push,
    send_email,
    send_sms,
    created_at
  ) VALUES (
    gen_random_uuid(),
    v_user_id,
    v_notification_title,
    v_notification_message,
    v_notification_type,
    NEW.id,
    'payment',
    'non_lue'::notification_status,
    false,
    false,
    false,
    true,
    true,
    NEW.status = 'failed'::payment_status,  -- SMS seulement pour les échecs
    now()
  );
  
  RETURN NEW;
END;
$$;

-- Créer le trigger sur la table payments
DROP TRIGGER IF EXISTS trigger_payment_status_notification ON payments;
CREATE TRIGGER trigger_payment_status_notification
AFTER UPDATE OF status ON payments
FOR EACH ROW
EXECUTE FUNCTION payment_status_notification();

-- 4. Fonction pour vérifier et valider un paiement (simulation de paiement externe)
CREATE OR REPLACE FUNCTION simulate_payment_validation(
  p_payment_id UUID,
  p_success BOOLEAN DEFAULT true
) RETURNS VOID LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_new_status payment_status;
  v_transaction_ref TEXT;
BEGIN
  -- Déterminer le nouveau statut
  IF p_success THEN
    v_new_status := 'completed'::payment_status;
    v_transaction_ref := 'SIM-' || gen_random_uuid()::text;
  ELSE
    v_new_status := 'failed'::payment_status;
    v_transaction_ref := NULL;
  END IF;
  
  -- Mettre à jour le statut du paiement
  PERFORM update_payment_status(p_payment_id, v_new_status, v_transaction_ref);
END;
$$;

-- 5. Gérer l'historique des paiements pour une réservation
CREATE OR REPLACE FUNCTION get_reservation_payment_history(
  p_reservation_id UUID
) RETURNS TABLE (
  payment_id UUID,
  amount DOUBLE PRECISION,
  method payment_method,
  status payment_status,
  transaction_reference TEXT,
  created_at TIMESTAMP WITH TIME ZONE
) LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  RETURN QUERY
  SELECT 
    id, 
    amount, 
    method, 
    status, 
    transaction_reference, 
    created_at
  FROM 
    payments
  WHERE 
    reservation_id = p_reservation_id
  ORDER BY 
    created_at DESC;
END;
$$;

-- 6. Calculer le total payé pour une réservation
CREATE OR REPLACE FUNCTION calculate_paid_amount(
  p_reservation_id UUID
) RETURNS DOUBLE PRECISION LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_total DOUBLE PRECISION;
BEGIN
  SELECT COALESCE(SUM(amount), 0)
  INTO v_total
  FROM payments
  WHERE reservation_id = p_reservation_id AND status = 'completed'::payment_status;
  
  RETURN v_total;
END;
$$; 