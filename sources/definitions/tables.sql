-- RAW.ORDERS - stands in for a dbt staging/source model.
-- CHANGE_TRACKING is on so a future dynamic table or stream could consume
-- incremental changes, same as it would off a real dbt source table.

DEFINE TABLE DCM_PROMO_DEMO.{{env_name}}_RAW.ORDERS (
    ORDER_ID NUMBER NOT NULL,
    CUSTOMER_ID NUMBER NOT NULL,
    ORDER_DATE DATE,
    TOTAL_AMOUNT NUMBER(12,2),
    STATUS VARCHAR(20) DEFAULT 'PENDING',
    CHANNEL VARCHAR(30) DEFAULT 'WEB'
)
CHANGE_TRACKING = TRUE
COMMENT = 'Raw order records - {{env_name}} (stand-in for a dbt source/staging model)';
