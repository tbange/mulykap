-- Table pour les voyages récurrents
CREATE TABLE recurring_trips (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  route_id UUID NOT NULL REFERENCES routes(id) ON DELETE CASCADE,
  bus_id UUID REFERENCES buses(id) ON DELETE SET NULL,
  driver_id UUID REFERENCES drivers(id) ON DELETE SET NULL,
  start_date DATE NOT NULL,
  end_date DATE,
  departure_time TIME NOT NULL,
  arrival_time TIME NOT NULL,
  base_price DECIMAL(10, 2) NOT NULL,
  recurrence_type TEXT NOT NULL CHECK (recurrence_type IN ('daily', 'weekly', 'monthly')),
  recurrence_days INTEGER[] NOT NULL,
  is_active BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Index pour améliorer les performances des requêtes
CREATE INDEX idx_recurring_trips_route_id ON recurring_trips(route_id);
CREATE INDEX idx_recurring_trips_bus_id ON recurring_trips(bus_id);
CREATE INDEX idx_recurring_trips_driver_id ON recurring_trips(driver_id);
CREATE INDEX idx_recurring_trips_start_date ON recurring_trips(start_date);
CREATE INDEX idx_recurring_trips_recurrence_type ON recurring_trips(recurrence_type);
CREATE INDEX idx_recurring_trips_is_active ON recurring_trips(is_active);

-- Trigger pour mettre à jour le champ updated_at
CREATE OR REPLACE FUNCTION update_recurring_trips_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = CURRENT_TIMESTAMP;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER recurring_trips_updated_at
  BEFORE UPDATE ON recurring_trips
  FOR EACH ROW
  EXECUTE FUNCTION update_recurring_trips_updated_at();

-- Fonction pour générer les voyages à partir des voyages récurrents
CREATE OR REPLACE FUNCTION generate_trips_from_recurring()
RETURNS void AS $$
DECLARE
  r RECORD;
  trip_date DATE;
  day_of_week INTEGER;
  day_of_month INTEGER;
BEGIN
  -- Parcourir tous les voyages récurrents actifs
  FOR r IN SELECT * FROM recurring_trips WHERE is_active = true LOOP
    -- Définir la date de début
    trip_date := CURRENT_DATE;
    
    -- Générer les voyages pour les 30 prochains jours
    WHILE trip_date <= CURRENT_DATE + INTERVAL '30 days' AND (r.end_date IS NULL OR trip_date <= r.end_date) LOOP
      -- Vérifier si le voyage doit être créé selon le type de récurrence
      CASE r.recurrence_type
        WHEN 'daily' THEN
          -- Créer le voyage quotidien
          INSERT INTO trips (
            route_id, bus_id, driver_id,
            departure_time, arrival_time,
            base_price, status
          )
          VALUES (
            r.route_id, r.bus_id, r.driver_id,
            trip_date + r.departure_time,
            trip_date + r.arrival_time,
            r.base_price, 'scheduled'
          )
          ON CONFLICT DO NOTHING;
          
        WHEN 'weekly' THEN
          -- Vérifier si le jour de la semaine est dans la liste
          day_of_week := EXTRACT(DOW FROM trip_date);
          IF day_of_week = ANY(r.recurrence_days) THEN
            INSERT INTO trips (
              route_id, bus_id, driver_id,
              departure_time, arrival_time,
              base_price, status
            )
            VALUES (
              r.route_id, r.bus_id, r.driver_id,
              trip_date + r.departure_time,
              trip_date + r.arrival_time,
              r.base_price, 'scheduled'
            )
            ON CONFLICT DO NOTHING;
          END IF;
          
        WHEN 'monthly' THEN
          -- Vérifier si le jour du mois est dans la liste
          day_of_month := EXTRACT(DAY FROM trip_date);
          IF day_of_month = ANY(r.recurrence_days) THEN
            INSERT INTO trips (
              route_id, bus_id, driver_id,
              departure_time, arrival_time,
              base_price, status
            )
            VALUES (
              r.route_id, r.bus_id, r.driver_id,
              trip_date + r.departure_time,
              trip_date + r.arrival_time,
              r.base_price, 'scheduled'
            )
            ON CONFLICT DO NOTHING;
          END IF;
      END CASE;
      
      -- Passer au jour suivant
      trip_date := trip_date + INTERVAL '1 day';
    END LOOP;
  END LOOP;
END;
$$ LANGUAGE plpgsql;

-- Créer un job pour exécuter la génération des voyages tous les jours à minuit
SELECT cron.schedule(
  'generate-trips',
  '0 0 * * *',
  $$SELECT generate_trips_from_recurring()$$
); 