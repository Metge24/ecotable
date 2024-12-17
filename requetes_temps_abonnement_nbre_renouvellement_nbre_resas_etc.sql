-- Calculer temps abonnement--
WITH cleaned_date AS (SELECT
  ID,
  State,
  REGEXP_REPLACE(Valid_Until, r', \d{2}:\d{2}', '') AS cleaned_valid_until,
  REGEXP_REPLACE(Committed_At, r', \d{2}:\d{2}', '') AS cleaned_committed_at
FROM `projet_ecotable.subscriptions`),

cast_date AS (SELECT
  ID,
  State,
  CAST(cleaned_valid_until AS DATE FORMAT 'MONTH DD, YYYY') AS valid_until,
  CAST(cleaned_committed_at AS DATE FORMAT 'MONTH DD, YYYY') AS committed_at
FROM cleaned_date)

SELECT
  ID,
  State,
  DATE_DIFF(valid_until,committed_at,MONTH) AS temps_abonnement
FROM cast_date


--Calculer le nombre de clicks par event type--
SELECT
  Name,
  COUNT(ID) AS event_type
FROM `projet_ecotable.tracking_event`
GROUP BY Name

  
--Calculer le nombre de résas via le site Ecotable--
SELECT 
  Params_____Link_Type,
  COUNT(ID) AS nb_resa
FROM `projet_ecotable.tracking_event`
WHERE Params_____Link_Type = 'booking_url'
GROUP BY Params_____Link_Type


--Calculer nombre de resto par resto_score avec abonnement actif--
SELECT 
  Denormalized_Resto_Score,
  COUNT(ID) AS nombre_restaurant
FROM `projet_ecotable.restaurants`
WHERE State = 'active'
GROUP BY Denormalized_Resto_Score
ORDER BY Denormalized_Resto_Score ASC


-- Calculer temps entre creation et activation compte--
WITH cleaned_date AS (SELECT
  ID,
  State,
  REGEXP_REPLACE(Created_At, r', \d{2}:\d{2}', '') AS cleaned_created_at,
  REGEXP_REPLACE(Activated_At, r', \d{2}:\d{2}', '') AS cleaned_activated_at
FROM `projet_ecotable.restaurants`),

cast_date AS (SELECT
  ID,
  State,
  CAST(cleaned_created_at AS DATE FORMAT 'MONTH DD, YYYY') AS created_at,
  CAST(cleaned_activated_at AS DATE FORMAT 'MONTH DD, YYYY') AS activated_at
FROM cleaned_date)

SELECT
  ID,
  State,
  DATE_DIFF(activated_at,created_at,DAY) AS temps_activation
FROM cast_date
ORDER BY temps_activation DESC


-- Calculer temps entre creation et update click event--
WITH cleaned_date AS (SELECT
  ID,
  REGEXP_EXTRACT(Created_At, r'^[^,]+,\s*\d{4}') AS cleaned_created_at,
  REGEXP_EXTRACT(Updated_At, r'^[^,]+,\s*\d{4}') AS cleaned_updated_at
FROM `projet_ecotable.tracking_event`),

cast_date AS (SELECT
  ID,
  CAST(cleaned_created_at AS DATE FORMAT 'MONTH DD, YYYY') AS created_at,
  CAST(cleaned_updated_at AS DATE FORMAT 'MONTH DD, YYYY') AS updated_at
FROM cleaned_date)

SELECT
  ID,
  DATE_DIFF(updated_at,created_at,DAY) AS temps_click_event
FROM cast_date
ORDER BY temps_click_event DESC


-- Calculer nb click par event type par jour--
WITH cleaned_date AS (SELECT
  ID,
  REGEXP_EXTRACT(Created_At, r'^[^,]+,\s*\d{4}') AS cleaned_created_at,
  Name
FROM `projet_ecotable.tracking_event`),

cast_date AS (SELECT
  ID,
  CAST(cleaned_created_at AS DATE FORMAT 'MONTH DD, YYYY') AS created_at,
  Name
FROM cleaned_date)

SELECT
  Name,
  created_at,
  COUNT(ID) AS nb_click
FROM cast_date
GROUP BY Name, created_at


-- Calculer nb click par resto par jour et par type d'event--
WITH cleaned_date AS (SELECT
  ID,
  Params_____User_ID AS resto_ID,
  REGEXP_EXTRACT(Created_At, r'^[^,]+,\s*\d{4}') AS cleaned_created_at,
  Name
FROM `projet_ecotable.tracking_event`),

cast_date AS (SELECT
  ID,
  resto_ID,
  CAST(cleaned_created_at AS DATE FORMAT 'MONTH DD, YYYY') AS created_at,
  Name
FROM cleaned_date)

SELECT
  resto_ID,
  created_at,
  Name,
  COUNT(ID) AS nb_click
FROM cast_date
WHERE resto_ID IS NOT NULL --à exclure : les ID des personnes d'écotable--
GROUP BY resto_ID, created_at, Name


--Voir si un resto avec un abonnement actif clique sur ses ressources impact--
SELECT
  resto.ID,
  resto.State,
  event.Params_____User_ID,
  event.Created_At,
  event.Name
FROM `projet_ecotable.restaurants` resto
LEFT JOIN `projet_ecotable.tracking_event` event 
ON resto.ID = event.Params_____User_ID
WHERE resto.State = 'active'


--Voir part de resto avec un abonnement actif qui cliquent sur les ressources impact--
--A modifier user si pas l'ID du resto--
WITH join_tables AS (SELECT
  resto.ID,
  resto.State,
  event.Params_____User_ID,
  event.Created_At,
  event.Name
FROM `projet_ecotable.restaurants` resto
LEFT JOIN `projet_ecotable.tracking_event` event 
ON resto.ID = event.Params_____User_ID
WHERE resto.State = 'active')

SELECT
  ROUND(COUNTIF(Params_____User_ID IS NOT NULL)/(COUNTIF(Params_____User_ID IS NULL)+COUNTIF(Params_____User_ID IS NOT NULL)),2) AS part_ressources
FROM join_tables



--calculer la rétention et le nombre de renouvellement--
-- Calculer temps abonnement--
WITH cleaned_date AS (SELECT
  ID,
  Company_ID,
  State,
  REGEXP_REPLACE(Valid_Until, r', \d{2}:\d{2}', '') AS cleaned_valid_until,
  REGEXP_REPLACE(Created_At, r', \d{2}:\d{2}', '') AS cleaned_created_at
FROM `agile-alignment-438607-u2.Ecotable_GB.Subscriptions`),

cast_date AS (SELECT
  ID,
  Company_ID,
  State,
  CAST(cleaned_valid_until AS DATE FORMAT 'MONTH DD, YYYY') AS valid_until,
  CAST(cleaned_created_at AS DATE FORMAT 'MONTH DD, YYYY') AS created_at
FROM cleaned_date)

SELECT
  ID,
  Company_ID,
  State,
  DATE_DIFF(valid_until,created_at,MONTH) AS temps_abonnement,
  --calculer la rétention si >=12 temps abonnement, 13, ou 14--
  CASE
    WHEN DATE_DIFF(valid_until,created_at,MONTH) > 11 THEN 1
    ELSE 0
    END AS retention_12,
  CASE
    WHEN DATE_DIFF(valid_until,created_at,MONTH) > 12 THEN 1
    ELSE 0
    END AS retention_13,
  CASE
    WHEN DATE_DIFF(valid_until,created_at,MONTH) > 13 THEN 1
    ELSE 0
    END AS retention_14,
  CASE
    WHEN DATE_DIFF(valid_until,created_at,MONTH) > 48 THEN 4
    WHEN DATE_DIFF(valid_until,created_at,MONTH) > 36 THEN 3
    WHEN DATE_DIFF(valid_until,created_at,MONTH) > 24 THEN 2
    WHEN DATE_DIFF(valid_until,created_at,MONTH) > 12 THEN 1
    ELSE 0
    END AS nb_renouvellement
FROM cast_date
--END--

