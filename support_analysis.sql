-- =====================================================
-- Banking support: which queries can an AI agent handle?
-- MySQL 8.0+  |  Data: Banking77 train.csv (PolyAI, CC BY 4.0)
-- =====================================================
USE support;

-- 1. Raw data, loaded untouched
DROP TABLE IF EXISTS queries;
CREATE TABLE queries (
  text     TEXT,
  category VARCHAR(100)
);

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/train.csv'
INTO TABLE queries
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES;

SELECT COUNT(*) AS total_queries FROM queries;   -- expect 10003

-- 2. Data quality checks
SELECT COUNT(*) AS blank_text  FROM queries WHERE TRIM(text) = '';
SELECT COUNT(*) - COUNT(DISTINCT text) AS duplicate_text FROM queries;
SELECT COUNT(DISTINCT category) AS intents FROM queries;               -- expect 77
SELECT DISTINCT category FROM queries
WHERE category <> LOWER(category) OR category LIKE '%?%';              -- inconsistent labels

-- 3. Business mapping: intent -> group + risk
--    risk 1 = general policy question (bot resolves)
--    risk 2 = needs this customer's account details (bot triages, agent resolves)
--    risk 3 = money loss, fraud/security, account closure (immediate human)
DROP TABLE IF EXISTS intent_map;
CREATE TABLE intent_map (
  intent         VARCHAR(100),
  business_group VARCHAR(50),
  risk           INT
);
INSERT INTO intent_map VALUES
  ('card_arrival', 'Card delivery & activation', 1),
  ('card_delivery_estimate', 'Card delivery & activation', 1),
  ('activate_my_card', 'Card delivery & activation', 1),
  ('order_physical_card', 'Card delivery & activation', 1),
  ('get_physical_card', 'Card delivery & activation', 1),
  ('getting_spare_card', 'Card delivery & activation', 1),
  ('card_about_to_expire', 'Card delivery & activation', 1),
  ('card_linking', 'Card delivery & activation', 1),
  ('card_acceptance', 'Card usage & features', 1),
  ('card_not_working', 'Card usage & features', 2),
  ('contactless_not_working', 'Card usage & features', 1),
  ('virtual_card_not_working', 'Card usage & features', 2),
  ('declined_card_payment', 'Card usage & features', 2),
  ('pin_blocked', 'Card usage & features', 1),
  ('change_pin', 'Card usage & features', 1),
  ('apple_pay_or_google_pay', 'Card usage & features', 1),
  ('visa_or_mastercard', 'Card usage & features', 1),
  ('supported_cards_and_currencies', 'Card usage & features', 1),
  ('getting_virtual_card', 'Card usage & features', 1),
  ('get_disposable_virtual_card', 'Card usage & features', 1),
  ('disposable_card_limits', 'Card usage & features', 1),
  ('card_swallowed', 'Card usage & features', 2),
  ('atm_support', 'Card usage & features', 1),
  ('card_payment_fee_charged', 'Fees & charges', 1),
  ('cash_withdrawal_charge', 'Fees & charges', 1),
  ('transfer_fee_charged', 'Fees & charges', 1),
  ('extra_charge_on_statement', 'Fees & charges', 2),
  ('exchange_charge', 'Fees & charges', 1),
  ('top_up_by_card_charge', 'Fees & charges', 1),
  ('top_up_by_bank_transfer_charge', 'Fees & charges', 1),
  ('card_payment_wrong_exchange_rate', 'Exchange rates & currencies', 2),
  ('wrong_exchange_rate_for_cash_withdrawal', 'Exchange rates & currencies', 2),
  ('exchange_rate', 'Exchange rates & currencies', 1),
  ('exchange_via_app', 'Exchange rates & currencies', 1),
  ('fiat_currency_support', 'Exchange rates & currencies', 1),
  ('country_support', 'Exchange rates & currencies', 1),
  ('pending_top_up', 'Top-ups', 2),
  ('top_up_reverted', 'Top-ups', 2),
  ('top_up_failed', 'Top-ups', 2),
  ('automatic_top_up', 'Top-ups', 1),
  ('verify_top_up', 'Top-ups', 1),
  ('top_up_by_cash_or_cheque', 'Top-ups', 1),
  ('topping_up_by_card', 'Top-ups', 1),
  ('top_up_limits', 'Top-ups', 1),
  ('transfer_not_received_by_recipient', 'Transfers', 2),
  ('balance_not_updated_after_bank_transfer', 'Transfers', 2),
  ('cancel_transfer', 'Transfers', 2),
  ('beneficiary_not_allowed', 'Transfers', 2),
  ('pending_transfer', 'Transfers', 2),
  ('failed_transfer', 'Transfers', 2),
  ('declined_transfer', 'Transfers', 2),
  ('transfer_timing', 'Transfers', 1),
  ('transfer_into_account', 'Transfers', 1),
  ('receiving_money', 'Transfers', 1),
  ('wrong_amount_of_cash_received', 'Cash, ATM & deposits', 3),
  ('declined_cash_withdrawal', 'Cash, ATM & deposits', 2),
  ('pending_cash_withdrawal', 'Cash, ATM & deposits', 2),
  ('balance_not_updated_after_cheque_or_cash_deposit', 'Cash, ATM & deposits', 2),
  ('request_refund', 'Card payments & refunds', 3),
  ('Refund_not_showing_up', 'Card payments & refunds', 2),
  ('reverted_card_payment?', 'Card payments & refunds', 2),
  ('pending_card_payment', 'Card payments & refunds', 2),
  ('transaction_charged_twice', 'Card payments & refunds', 3),
  ('direct_debit_payment_not_recognised', 'Fraud & security', 3),
  ('card_payment_not_recognised', 'Fraud & security', 3),
  ('cash_withdrawal_not_recognised', 'Fraud & security', 3),
  ('compromised_card', 'Fraud & security', 3),
  ('lost_or_stolen_card', 'Fraud & security', 3),
  ('lost_or_stolen_phone', 'Fraud & security', 3),
  ('why_verify_identity', 'Account & identity', 1),
  ('verify_my_identity', 'Account & identity', 1),
  ('unable_to_verify_identity', 'Account & identity', 2),
  ('verify_source_of_funds', 'Account & identity', 1),
  ('edit_personal_details', 'Account & identity', 2),
  ('age_limit', 'Account & identity', 1),
  ('terminate_account', 'Account & identity', 3),
  ('passcode_forgotten', 'Account & identity', 2);

-- every intent mapped? expect 0
SELECT COUNT(*) AS unmapped FROM queries q
LEFT JOIN intent_map m ON q.category = m.intent
WHERE m.intent IS NULL;

-- 4. Volume by intent
SELECT q.category AS intent, m.business_group, m.risk,
       COUNT(*) AS queries,
       ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS pct_of_total
FROM queries q
JOIN intent_map m ON q.category = m.intent
GROUP BY q.category, m.business_group, m.risk
ORDER BY queries DESC;

-- 5. Volume by business group, split by risk
SELECT m.business_group,
       COUNT(*)          AS queries,
       ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1) AS pct_of_total,
       SUM(m.risk = 1)   AS bot_resolvable,
       SUM(m.risk = 2)   AS triage_to_agent,
       SUM(m.risk = 3)   AS human_only,
       ROUND(100.0 * SUM(m.risk = 1) / COUNT(*), 1) AS pct_bot_resolvable
FROM queries q
JOIN intent_map m ON q.category = m.intent
GROUP BY m.business_group
ORDER BY bot_resolvable DESC;

-- 6. Overall split by risk
SELECT m.risk, COUNT(*) AS queries,
       ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1) AS pct_of_total
FROM queries q
JOIN intent_map m ON q.category = m.intent
GROUP BY m.risk
ORDER BY m.risk;

-- 7. Pull test questions for UAT (5 random real queries per pilot intent)
SELECT category, text FROM (
  SELECT q.category, q.text,
         ROW_NUMBER() OVER (PARTITION BY q.category ORDER BY RAND()) AS rn
  FROM queries q
  JOIN intent_map m ON q.category = m.intent
  WHERE m.risk = 1
    AND m.business_group IN ('Card usage & features','Card delivery & activation',
                             'Fees & charges','Top-ups')
) x
WHERE rn <= 5;
