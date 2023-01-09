PACKAGE BODY PKG_SUM_STG_LOAN_DIM AS
    
    --- 0.
    PROCEDURE MAIN(DATE_ DATE) AS
    BEGIN
        GET_LOAN_DIM_1M(DATE_);
        GET_LOAN_DIM_TIME_WINDOW(DATE_, 3);
        GET_LOAN_DIM_TIME_WINDOW_LAG(DATE_, 1, 3);
        GET_LOAN_DIM_TIME_WINDOW_LAG(DATE_, 3, 1);
        GET_LOAN_DIM_XXXM_SUMMARY(DATE_, 3);
        GET_LOAN_DIM_AVG_GR_RATE(DATE_, 3);
        GET_LOAN_DIM_3M(DATE_);
        TRUNC_TEMP_TABS;
        
        GET_LOAN_DIM_TIME_WINDOW(DATE_, 6);
        GET_LOAN_DIM_TIME_WINDOW_LAG(DATE_, 1, 6);
        GET_LOAN_DIM_TIME_WINDOW_LAG(DATE_, 6, 1);
        GET_LOAN_DIM_XXXM_SUMMARY(DATE_, 6);
        GET_LOAN_DIM_AVG_GR_RATE(DATE_, 6);
        GET_LOAN_DIM_6M(DATE_);
        TRUNC_TEMP_TABS;
        
        GET_LOAN_DIM_TIME_WINDOW(DATE_, 9);
        GET_LOAN_DIM_TIME_WINDOW_LAG(DATE_, 1, 9);
        GET_LOAN_DIM_XXXM_SUMMARY(DATE_, 9);
        GET_LOAN_DIM_AVG_GR_RATE(DATE_, 9);
        GET_LOAN_DIM_9M(DATE_);
        TRUNC_TEMP_TABS;
        
        GET_LOAN_DIM_TIME_WINDOW(DATE_, 12);
        GET_LOAN_DIM_TIME_WINDOW_LAG(DATE_, 1, 12);
        GET_LOAN_DIM_XXXM_SUMMARY(DATE_, 12);
        GET_LOAN_DIM_AVG_GR_RATE(DATE_, 12);
        GET_LOAN_DIM_12M(DATE_);
        TRUNC_TEMP_TABS;
    END;
    
    -- 1.
    PROCEDURE GET_LOAN_DIM_1M(DATE_ DATE) AS
    BEGIN
    PKG_LOGS.LOG('PKG_SUM_STG_LOAN_DIM', 'GET_STG_LOAN_DIM_1M', DATE_, 'BEGIN');
        DELETE FROM GET_LOAN_DIM_1M WHERE SNAPSHOT_DATE = DATE_;
        COMMIT;
        
        INSERT INTO GET_LOAN_DIM_1M
        WITH D0 AS (
                    SELECT * FROM PD.STG_LOAN_DIM
                    WHERE 1=1
                    AND SNAPSHOT_DATE = DATE_
                    AND SNAPSHOT_DATE <= LAST_DAY(LEAST(NVL(INSTR_MATURITY_DATE, SNAPSHOT_DATE), NVL(LOAN_MATURITY_DATE, SNAPSHOT_DATE), NVL(INSTR_WITHDRAW_DATE, SNAPSHOT_DATE)))
                    ),--- (3) CHI LOC CAC HOP DONG CON HIEU LUC TAI THANG QUAN SAT (FIX)
            D9   AS ( 
                        SELECT CUSTOMER_ID, TO_DATE(DATE_) AS SNAPSHOT_DATE,
                         MAX(B9) AS D9
                         FROM  
                         (SELECT SNAPSHOT_DATE, CUSTOMER_ID,INSTR_NBR
                         , MONTHS_BETWEEN(SNAPSHOT_DATE,INSTR_DISBURSE_DATE)  AS B9
                                FROM D0 
                                WHERE 1=1                                         
                                GROUP BY SNAPSHOT_DATE, CUSTOMER_ID,INSTR_NBR,INSTR_DISBURSE_DATE)                                                                 
                          WHERE 1=1
                          AND SNAPSHOT_DATE = DATE_ 
                          GROUP BY SNAPSHOT_DATE,CUSTOMER_ID
                    ),
        
            D11  AS ( 
                      SELECT CUSTOMER_ID, TO_DATE(DATE_) AS SNAPSHOT_DATE,
                          MAX(B11)  AS D11
                         FROM 
                               (SELECT SNAPSHOT_DATE, CUSTOMER_ID,INSTR_NBR,  MAX(MONTHS_BETWEEN( LOAN_MATURITY_DATE, SNAPSHOT_DATE))  AS B11
                                FROM D0 
                                WHERE 1=1                                         
                                 GROUP BY SNAPSHOT_DATE, CUSTOMER_ID,INSTR_NBR)   
                          WHERE 1=1
                    AND SNAPSHOT_DATE BETWEEN ADD_MONTHS(DATE_, 0) AND DATE_
                    GROUP BY SNAPSHOT_DATE,CUSTOMER_ID
                         ),
           D12  AS ( 
                      SELECT CUSTOMER_ID, TO_DATE(DATE_) AS SNAPSHOT_DATE,
                       MAX(B12)  AS D12
                         FROM
                               (SELECT SNAPSHOT_DATE, CUSTOMER_ID,INSTR_NBR,  MONTHS_BETWEEN(LOAN_MATURITY_DATE, INSTR_DISBURSE_DATE)  AS B12
                                FROM D0 
                                WHERE 1=1                                         
--                                 GROUP BY SNAPSHOT_DATE, CUSTOMER_ID ,INSTR_NBR ,INSTR_OFFER_EXPIRY_DATE
                                 ) 
                          WHERE 1=1
                    AND SNAPSHOT_DATE BETWEEN ADD_MONTHS(DATE_, 0) AND DATE_
                    GROUP BY SNAPSHOT_DATE, CUSTOMER_ID
                ),
          GR1 AS ( 
                   
               SELECT CUSTOMER_ID, SNAPSHOT_DATE,
                       SUM(INSTR_AVG_OUSTANDING_LCY_AMT) AS  D1_D4,  --D1,D2,D3,D4
                       MAX(GREATEST(INSTR_DPD_NO, INSTR_DPD_MAX_NO))   AS  D32_D35, --D32, D33, D34, D35
                       MIN(GREATEST(INSTR_DPD_NO, INSTR_DPD_MAX_NO)) AS D36_D39, --D36, D37, D38, D39,
                       SUM(INSTR_DISBUR_LCY_AMT)/REPLACE_ZERO_TO_ONE(SUM(INSTR_DISBURSE_ORIGINAL_AMT/REPLACE_ZERO_TO_ONE(LTV_RATIO))) AS LTV_RATIO,
        --                                 --- (1) BO SUNG BIEN D40, D41, D42
                      (CASE WHEN  MAX(GREATEST(INSTR_DPD_NO, INSTR_DPD_MAX_NO))  >0 THEN 1 ELSE 0 END) AS D43_D46,--D43, D44, D45, D46,  -- (4) TINH MAX SO NGAY QUA HAN CHO TUNG KH TAI THANG QUAN SAT SAU DO FLAG 1 NEU MAX_DPD_NO > 0(FIX)
                      (CASE WHEN  MAX(GREATEST(INSTR_DPD_NO, INSTR_DPD_MAX_NO)) >10 THEN 1 ELSE 0 END) AS D63,--D47, D48, D49, D50,  D63 -- (5) TINH MAX SO NGAY QUA HAN CHO TUNG KH TAI THANG QUAN SAT SAU DO FLAG 1 NEU MAX_DPD_NO > 10(FIX)
                      (CASE WHEN  MAX(GREATEST(INSTR_DPD_NO, INSTR_DPD_MAX_NO)) >30 THEN 1 ELSE 0 END) AS D64,--D51, D52, D53, D54, D64 -- (6) TINH MAX SO NGAY QUA HAN CHO TUNG KH TAI THANG QUAN SAT SAU DO FLAG 1 NEU MAX_DPD_NO > 30(FIX)
                      (CASE WHEN  MAX(GREATEST(INSTR_DPD_NO, INSTR_DPD_MAX_NO)) >60 THEN 1 ELSE 0 END) AS D65,--D55, D56, D57, D58, D65 -- (7) TINH MAX SO NGAY QUA HAN CHO TUNG KH TAI THANG QUAN SAT SAU DO FLAG 1 NEU MAX_DPD_NO > 60(FIX)
                      (CASE WHEN  MAX(GREATEST(INSTR_DPD_NO, INSTR_DPD_MAX_NO)) >90 THEN 1 ELSE 0 END) AS D66,--D59, D60, D61, D62, D66 -- (8) TINH MAX SO NGAY QUA HAN CHO TUNG KH TAI THANG QUAN SAT SAU DO FLAG 1 NEU MAX_DPD_NO > 90(FIX)
                      (CASE WHEN  MAX(GREATEST(INSTR_DPD_NO, INSTR_DPD_MAX_NO)) > 0 AND MAX(GREATEST(INSTR_DPD_NO, INSTR_DPD_MAX_NO)) <=10  THEN 1 ELSE 0 END) AS D67_D70,--D67, D68, D69,D70
                      (CASE WHEN  MAX(GREATEST(INSTR_DPD_NO, INSTR_DPD_MAX_NO)) > 10 AND MAX(GREATEST(INSTR_DPD_NO, INSTR_DPD_MAX_NO)) <=30  THEN 1 ELSE 0 END) AS D71_D74, --D71, D72, D73, D74
                      (CASE WHEN  MAX(GREATEST(INSTR_DPD_NO, INSTR_DPD_MAX_NO)) > 30 AND MAX(GREATEST(INSTR_DPD_NO, INSTR_DPD_MAX_NO)) <=60  THEN 1 ELSE 0 END) AS D75_D78, --D75, D76, D77, D78
                      (CASE WHEN  MAX(GREATEST(INSTR_DPD_NO, INSTR_DPD_MAX_NO)) > 60 AND MAX(GREATEST(INSTR_DPD_NO, INSTR_DPD_MAX_NO)) <=90  THEN 1 ELSE 0 END) AS D79_D82, --D79, D80 D81, D82
                      MAX (INSTR_CREDIT_CODE_BF_CIC) AS D87_D90, --D87, D88, D89, D90  -- (11) BO SUNG BIEN 1M CHO BIEN D87 -> D90(FIX)
                      (CASE WHEN  MAX (INSTR_CREDIT_CODE_CIC) > 2 THEN 1 ELSE 0 END )  AS D91_D94, --D91, D92, D93, D94     
                      (CASE WHEN  MAX (INSTR_CREDIT_CODE_BF_CIC) > 2 THEN 1 ELSE 0 END )  AS D95_D98, --D95, D96, D97, D98
                       (CASE WHEN SUM (INSTR_PAYMENT_LCY_AMT)> SUM(INSTR_OUSTANDING_LCY_AMT) THEN 1 ELSE 0 END ) AS D119_D122, --D119, D120, D121,D122 -- (14) BO SUNG BIEN 1M CHO BIEN D119 -> D122
                       SUM(INSTR_PAYMENT_LCY_AMT) AS D123_D126, --D123, D124, D125, D126
                       GREATEST(MAX(INSTR_DPD_NO), MAX(INSTR_DPD_MAX_NO)) AS D148,   -- (16) BO SUNG BIEN 1M CHO BIEN D148 (FIX)
                       SUM(INSTR_AVG_OUSTANDING_LCY_AMT) AS  D154,
                       MAX(INSTR_OUSTANDING_LCY_AMT) AS D155,
--                       SUM(INSTR_PAYMENT_AMT)/(REPLACE_ZERO_TO_ONE(SUM(INSTR_AUTH_LCY_AMT))) AS D156,
                       MAX (INSTR_CREDIT_CODE_CIC) AS D158, --D83, D84, D85, D86   -- (10) BO SUNG BIEN 1M CHO BIEN D83 -> D86(FIX)
                       SUM (INSTR_PAYMENT_LCY_AMT)/REPLACE_ZERO_TO_ONE( SUM(INSTR_OUSTANDING_LCY_AMT)) AS D159 --D107, D108, D109, D110
                     
                     FROM D0
                 
                    WHERE 1=1
                     GROUP BY SNAPSHOT_DATE, CUSTOMER_ID
                        ),
           GR2 AS (   
                   SELECT CUSTOMER_ID, TO_DATE(DATE_) AS SNAPSHOT_DATE,
                        SUM(A1)/REPLACE_ZERO_TO_ONE(SUM(A2)) AS D127,--D128, D129, D130, D131,
                        ( CASE WHEN  SUM(A1)/REPLACE_ZERO_TO_ONE(SUM(A2)) > 0.8 THEN 1 ELSE 0 END) AS D140_D143,
                        ( CASE WHEN  SUM(A1)/REPLACE_ZERO_TO_ONE(SUM(A2)) > 1 THEN 1 ELSE 0 END) AS D144_D147,
                        SUM(A3)/(REPLACE_ZERO_TO_ONE(SUM(A2))) AS D156
                             FROM  ( 
                              SELECT  SNAPSHOT_DATE,CUSTOMER_ID, INSTR_NBR,  
                              SUM(INSTR_OUSTANDING_LCY_AMT) AS A1,
                              SUM(INSTR_PAYMENT_LCY_AMT) AS A3,
                              CASE WHEN MAX(INSTR_AUTH_LCY_AMT) IS NULL OR MAX(INSTR_AUTH_LCY_AMT) = 0 
                                    THEN NVL(SUM(INSTR_DISBUR_LCY_AMT), SUM(INSTR_OUSTANDING_LCY_AMT)) 
                                    ELSE MAX(INSTR_AUTH_LCY_AMT) END AS A2
                                      FROM D0                    
                            WHERE 1=1
                            GROUP BY SNAPSHOT_DATE, CUSTOMER_ID,INSTR_NBR)
                            WHERE 1=1 
                            GROUP BY   SNAPSHOT_DATE, CUSTOMER_ID )                 
                
        , GR3 AS (
                SELECT A.CUSTOMER_ID, A.SNAPSHOT_DATE
                        , A.D154/REPLACE_ZERO_TO_ONE(B.D154) AS D149 
                        , A.D123_D126/REPLACE_ZERO_TO_ONE(B.D123_D126) AS D150
                FROM GR1 A
                LEFT JOIN 
                    (
                        SELECT CUSTOMER_ID, D154, D123_D126 
                        FROM GET_LOAN_DIM_1M
                        WHERE SNAPSHOT_DATE = ADD_MONTHS(DATE_, -1)
                    ) B
                ON A.CUSTOMER_ID = B.CUSTOMER_ID
                )
                
                SELECT 
                        GR1.CUSTOMER_ID AS CUSTOMER_ID,
                        GR1.SNAPSHOT_DATE AS SNAPSHOT_DATE,
                        D9.D9 AS D9,
                        D11.D11 AS D11,
                        D12.D12 AS D12,
                        GR1.D1_D4  AS D1_D4,
                        GR1.D32_D35 AS D32_D35,
                        GR1.D36_D39 AS D36_D39,
                        GR1.LTV_RATIO AS LTV_RATIO,
                        GR1.D43_D46 AS D43_D46,
                        GR1.D63 AS D63, 
                        GR1.D64 AS D64,
                        GR1.D65 AS D65,
                        GR1.D66 AS D66,
                        GR1.D67_D70 AS D67_D70,
                        GR1.D71_D74 AS D71_D74,
                        GR1.D75_D78 AS D75_D78,
                        GR1.D79_D82 AS D79_D82,
                        GR1.D87_D90 AS D87_D90,
                        GR1.D91_D94 AS D91_D94,
                        GR1.D95_D98 AS D95_D98,
                        GR1.D119_D122 AS D119_D122,
                        GR1.D123_D126 AS D123_D126,
                        GR2.D127 AS D127,
                        GR2.D140_D143 AS D140_D143,
                        GR2.D144_D147 AS D144_D147,
                        GR1.D148 AS D148,
                        GR3.D149 AS D149,
                        GR3.D150 AS D150,
                        GR1.D154 AS D154,
                        GR1.D155 AS D155,
                        GR2.D156 AS D156,
                        GR1.D158 AS D158,    
                        GR1.D159 AS D159
        FROM D9 LEFT JOIN D11
        ON D9.CUSTOMER_ID = D11.CUSTOMER_ID AND D9.SNAPSHOT_DATE = D11.SNAPSHOT_DATE 
        LEFT JOIN D12
        ON D9.CUSTOMER_ID = D12.CUSTOMER_ID AND D9.SNAPSHOT_DATE = D12.SNAPSHOT_DATE
        LEFT JOIN GR1
        ON D9.CUSTOMER_ID = GR1.CUSTOMER_ID AND D9.SNAPSHOT_DATE = GR1.SNAPSHOT_DATE
        LEFT JOIN GR2
         ON D9.CUSTOMER_ID = GR2.CUSTOMER_ID AND D9.SNAPSHOT_DATE = GR2.SNAPSHOT_DATE
        LEFT JOIN GR3
         ON D9.CUSTOMER_ID = GR3.CUSTOMER_ID AND D9.SNAPSHOT_DATE = GR3.SNAPSHOT_DATE
        ;
        COMMIT;
        
        PKG_LOGS.LOG('PKG_SUM_STG_LOAN_DIM', 'GET_STG_LOAN_DIM_1M', DATE_, 'END');
    END GET_LOAN_DIM_1M;
    
    --- 2.
    PROCEDURE GET_LOAN_DIM_TIME_WINDOW(DATE_ DATE, T NUMBER) AS
    BEGIN
        PKG_LOGS.LOG('PKG_SUM_STG_LOAN_DIM', 'GET_LOAN_DIM_TIME_WINDOW', DATE_, 'BEGIN');

        DELETE FROM GET_LOAN_DIM_TIME_WINDOW WHERE SNAPSHOT_DATE_ROOT = DATE_;
        COMMIT;
        
        INSERT INTO GET_LOAN_DIM_TIME_WINDOW
        SELECT A.*, TO_DATE(DATE_) AS SNAPSHOT_DATE_ROOT, T AS PERIOD_WINDOW FROM GET_LOAN_DIM_1M A
        LEFT JOIN (SELECT CUSTOMER_ID, SNAPSHOT_DATE FROM GET_LOAN_DIM_1M WHERE SNAPSHOT_DATE = DATE_) B
        ON A.CUSTOMER_ID = B.CUSTOMER_ID
        WHERE 1=1
        AND A.SNAPSHOT_DATE <= DATE_ 
        AND A.SNAPSHOT_DATE > ADD_MONTHS(DATE_, -1*T)
        AND B.CUSTOMER_ID IS NOT NULL;
        COMMIT;
        
        PKG_LOGS.LOG('PKG_SUM_STG_LOAN_DIM', 'GET_LOAN_DIM_TIME_WINDOW', DATE_, 'END');
    END GET_LOAN_DIM_TIME_WINDOW;
  
    --- 3.
    PROCEDURE GET_LOAN_DIM_TIME_WINDOW_LAG(DATE_ DATE, LAG_ NUMBER, T NUMBER) AS
    BEGIN
        PKG_LOGS.LOG('PKG_SUM_STG_LOAN_DIM', 'GET_LOAN_DIM_TIME_WINDOW_LAG', DATE_, 'BEGIN');
        DELETE FROM GET_LOAN_DIM_1M_LAG WHERE SNAPSHOT_DATE_ROOT = DATE_ AND LAG = LAG_;
        COMMIT;
        
        INSERT INTO GET_LOAN_DIM_1M_LAG
        SELECT B.CUSTOMER_ID, TO_DATE(DATE_) AS SNAPSHOT_DATE_ROOT, ADD_MONTHS(A.SNAPSHOT_DATE, LAG_) AS SNAPSHOT_DATE, LAG_ AS LAG
        , D9, D11, D12, D1_D4, D32_D35, D36_D39, LTV_RATIO
        , D43_D46, D63, D64, D65, D66, D67_D70, D71_D74, D75_D78, D79_D82, D87_D90, D91_D94
        , D95_D98, D119_D122, D123_D126, D127, D140_D143, D144_D147, D148, D154, D155, D156
        , D158, D159
        FROM GET_LOAN_DIM_1M A
        LEFT JOIN 
            (SELECT CUSTOMER_ID, SNAPSHOT_DATE FROM GET_LOAN_DIM_1M WHERE SNAPSHOT_DATE = DATE_) B
        ON A.CUSTOMER_ID = B.CUSTOMER_ID
        WHERE 1=1
        AND A.SNAPSHOT_DATE <= ADD_MONTHS(DATE_, -1*LAG_) 
        AND A.SNAPSHOT_DATE > ADD_MONTHS(ADD_MONTHS(DATE_, -1*LAG_), -1*T)
        AND B.CUSTOMER_ID IS NOT NULL
        ;
        COMMIT;
        PKG_LOGS.LOG('PKG_SUM_STG_LOAN_DIM', 'GET_LOAN_DIM_TIME_WINDOW_LAG', DATE_, 'BEGIN');
    END GET_LOAN_DIM_TIME_WINDOW_LAG;
    
    --- 4.
    PROCEDURE GET_LOAN_DIM_XXXM_SUMMARY(DATE_ DATE, T NUMBER) AS
    BEGIN
        PKG_LOGS.LOG('PKG_SUM_STG_LOAN_DIM', 'GET_LOAN_DIM_XXXM_SUMMARY', DATE_, 'BEGIN');
        DELETE FROM GET_LOAN_DIM_XXXM_SUMMARY WHERE SNAPSHOT_DATE = DATE_;
        COMMIT;
        
        INSERT INTO GET_LOAN_DIM_XXXM_SUMMARY
        SELECT CUSTOMER_ID, SNAPSHOT_DATE_ROOT AS SNAPSHOT_DATE, PERIOD_WINDOW,
                SUM(D1_D4)/T AS D1,
                MAX(D1_D4) AS D5,
                MIN(D156) AS D23,
                MAX(D156) AS D27,
                SUM(D156)/T AS D31,
                MAX(D148) AS D35,
                MIN(D148) AS D39,
                SUM(D43_D46) AS D43,
                SUM(D63) AS D47,
                SUM(D64) AS D51,
                SUM(D65) AS D55,
                SUM(D66) AS D59,
                SUM(D67_D70) AS D67,
                SUM(D71_D74) AS D71,
                SUM(D75_D78) AS D75,
                SUM(D79_D82) AS D79,
                MAX(D158) AS D83,
                MAX(D87_D90) AS D87,
                SUM(D91_D94) AS D91,
                SUM(D95_D98) AS D95,
                SUM(D159)/T AS D107,
                SUM(CASE WHEN D159 > 1 THEN 1 ELSE 0 END)/T AS D119,
                SUM(CASE WHEN D123_D126 > 0 THEN 1 ELSE 0 END)/T AS D123,
                SUM(D127)/T AS D128,
                MAX(D127) AS D132,
                MIN(D127) AS D136,
                SUM(CASE WHEN D127 > 0.8 THEN 1 ELSE 0 END)/T AS D140,
                SUM(CASE WHEN D127 > 1 THEN 1 ELSE 0 END)/T AS D144,
                MAX(LTV_RATIO) AS D160,
                MIN(LTV_RATIO) AS D161,
                SUM(LTV_RATIO)/T AS D162
        FROM GET_LOAN_DIM_TIME_WINDOW
        WHERE 1=1
        AND SNAPSHOT_DATE_ROOT = DATE_
        GROUP BY CUSTOMER_ID, SNAPSHOT_DATE_ROOT, PERIOD_WINDOW
        ;
        COMMIT;
        PKG_LOGS.LOG('PKG_SUM_STG_LOAN_DIM', 'GET_LOAN_DIM_XXXM_SUMMARY', DATE_, 'END');
    END GET_LOAN_DIM_XXXM_SUMMARY;
  
    --- 5.
    PROCEDURE GET_LOAN_DIM_AVG_GR_RATE(DATE_ DATE, T NUMBER) AS
    BEGIN
        PKG_LOGS.LOG('PKG_SUM_STG_LOAN_DIM', 'GET_LOAN_DIM_AVG_GR_RATE', DATE_, 'BEGIN');
        DELETE FROM GET_LOAN_DIM_AVG_GR_RATE WHERE SNAPSHOT_DATE = DATE_;
        COMMIT;
        
        INSERT INTO GET_LOAN_DIM_AVG_GR_RATE
        WITH DAT AS
        (
            SELECT A.CUSTOMER_ID, A.SNAPSHOT_DATE_ROOT, A.SNAPSHOT_DATE, A.PERIOD_WINDOW,
                    A.D149,
                    GROWTH_RATE(A.LTV_RATIO, B.LTV_RATIO) AS D19_SUB
            FROM (SELECT *
                    FROM GET_LOAN_DIM_TIME_WINDOW 
                    WHERE SNAPSHOT_DATE_ROOT = DATE_) A
            LEFT JOIN (SELECT *
                        FROM GET_LOAN_DIM_1M_LAG 
                        WHERE LAG = 1) B
            ON  A.CUSTOMER_ID = B.CUSTOMER_ID
                AND A.SNAPSHOT_DATE = B.SNAPSHOT_DATE
            WHERE 1=1
    --        GROUP BY A.CUSTOMER_ID, A.SNAPSHOT_DATE_ROOT, A.PERIOD_WINDOW
        )
        
        , DAT1 AS 
        (
            SELECT DISTINCT CUSTOMER_ID, SNAPSHOT_DATE_ROOT, ADD_MONTHS(DATE_, 1) AS SNAPSHOT_DATE, PERIOD_WINDOW
            FROM DAT
            
            UNION ALL
            SELECT CUSTOMER_ID, SNAPSHOT_DATE_ROOT, SNAPSHOT_DATE, PERIOD_WINDOW
            FROM DAT
            WHERE 1=1
            AND D149 >= 1
            
            UNION ALL
            SELECT DISTINCT CUSTOMER_ID, SNAPSHOT_DATE_ROOT, ADD_MONTHS(DATE_, -1*T) AS SNAPSHOT_DATE, PERIOD_WINDOW
            FROM DAT
        )
        
        , D103_TEMP AS
        (
                SELECT A.*, LAG(A.SNAPSHOT_DATE, 1) OVER(PARTITION BY A.CUSTOMER_ID ORDER BY A.SNAPSHOT_DATE DESC) AS SNAPSHOT_DATE_LAG1
                FROM DAT1 A
                WHERE 1=1
        )
        
        SELECT A.CUSTOMER_ID, A.SNAPSHOT_DATE_ROOT AS SNAPSHOT_DATE, A.PERIOD_WINDOW,
                SUM(A.D19_SUB)/T AS D19,
                MAX(MONTHS_BETWEEN(B.SNAPSHOT_DATE_LAG1, B.SNAPSHOT_DATE) - 1) AS D103
        FROM DAT A
        LEFT JOIN D103_TEMP B
        ON A.CUSTOMER_ID = B.CUSTOMER_ID AND A.SNAPSHOT_DATE_ROOT = B.SNAPSHOT_DATE_ROOT 
            AND A.PERIOD_WINDOW = B.PERIOD_WINDOW
        WHERE 1=1
        GROUP BY A.CUSTOMER_ID, A.SNAPSHOT_DATE_ROOT, A.PERIOD_WINDOW
        ;
        COMMIT;
        
        PKG_LOGS.LOG('PKG_SUM_STG_LOAN_DIM', 'GET_LOAN_DIM_AVG_GR_RATE', DATE_, 'END');
    END GET_LOAN_DIM_AVG_GR_RATE;
    
    --- 7.
    PROCEDURE GET_LOAN_DIM_3M(DATE_ DATE) AS
        T NUMBER;
    BEGIN
        T := 3;
        PKG_LOGS.LOG('PKG_SUM_STG_LOAN_DIM', 'GET_LOAN_DIM_3M', DATE_, 'BEGIN');
        DELETE FROM GET_LOAN_DIM_3M WHERE SNAPSHOT_DATE = DATE_;
        COMMIT;
        
        INSERT INTO GET_LOAN_DIM_3M
        SELECT A.CUSTOMER_ID, A.SNAPSHOT_DATE, A.PERIOD_WINDOW,
                A.D1,
                A.D5,
                B.D19,
                A.D23,
                A.D27,
                A.D31,
                A.D35,
                A.D39,
                A.D43,
                A.D47,
                A.D51,
                A.D55,
                A.D59,
                A.D67,
                A.D71,
                A.D75,
                A.D79,
                A.D83,
                A.D87,
                A.D91,
                A.D95,
                B.D103,
                A.D107,
                A.D119,
                A.D123,
                A.D128,
                A.D132,
                A.D136,
                A.D140,
                A.D144,
                A.D160,
                A.D161,
                A.D162
        FROM GET_LOAN_DIM_XXXM_SUMMARY A
        LEFT JOIN GET_LOAN_DIM_AVG_GR_RATE B
        ON A.CUSTOMER_ID = B.CUSTOMER_ID AND A.SNAPSHOT_DATE = B.SNAPSHOT_DATE AND A.PERIOD_WINDOW = B.PERIOD_WINDOW
        WHERE 1=1
        AND A.SNAPSHOT_DATE = DATE_
        ;
        COMMIT;
        PKG_LOGS.LOG('PKG_SUM_STG_LOAN_DIM', 'GET_LOAN_DIM_3M', DATE_, 'END');
        
    END GET_LOAN_DIM_3M;
    
    --- 7.
    PROCEDURE GET_LOAN_DIM_6M(DATE_ DATE) AS
        T NUMBER;
    BEGIN
        T := 6;
        PKG_LOGS.LOG('PKG_SUM_STG_LOAN_DIM', 'GET_LOAN_DIM_3M', DATE_, 'BEGIN');
        DELETE FROM GET_LOAN_DIM_6M WHERE SNAPSHOT_DATE = DATE_;
        COMMIT;
        
        INSERT INTO GET_LOAN_DIM_6M
        SELECT A.CUSTOMER_ID, A.SNAPSHOT_DATE, A.PERIOD_WINDOW,
                A.D1 AS D2,
                A.D5 AS D6,
                B.D19 AS D18,
                A.D23 AS D22,
                A.D27 AS D26,
                A.D31 AS D30,
                A.D35 AS D34,
                A.D39 AS D38,
                A.D43 AS D44,
                A.D47 AS D48,
                A.D51 AS D52,
                A.D55 AS D56,
                A.D59 AS D60,
                A.D67 AS D68,
                A.D71 AS D72,
                A.D75 AS D76,
                A.D79 AS D80,
                A.D83 AS D84,
                A.D87 AS D88,
                A.D91 AS D92,
                A.D95 AS D96,
                B.D103 AS D104,
                A.D107 AS D108,
                A.D119 AS D120,
                A.D123 AS D124,
                A.D128 AS D129,
                A.D132 AS D133,
                A.D136 AS D137,
                A.D140 AS D141,
                A.D144 AS D145,
                A.D160 AS D163,
                A.D161 AS D164,
                A.D162 AS D165
        FROM GET_LOAN_DIM_XXXM_SUMMARY A
        LEFT JOIN GET_LOAN_DIM_AVG_GR_RATE B
        ON A.CUSTOMER_ID = B.CUSTOMER_ID AND A.SNAPSHOT_DATE = B.SNAPSHOT_DATE AND A.PERIOD_WINDOW = B.PERIOD_WINDOW
        WHERE 1=1
        AND A.SNAPSHOT_DATE = DATE_
        ;
        COMMIT;
        PKG_LOGS.LOG('PKG_SUM_STG_LOAN_DIM', 'GET_LOAN_DIM_6M', DATE_, 'END');
        
    END GET_LOAN_DIM_6M;
    
    
    --- 7.
    PROCEDURE GET_LOAN_DIM_9M(DATE_ DATE) AS
        T NUMBER;
    BEGIN
        T := 9;
        PKG_LOGS.LOG('PKG_SUM_STG_LOAN_DIM', 'GET_LOAN_DIM_9M', DATE_, 'BEGIN');
        DELETE FROM GET_LOAN_DIM_9M WHERE SNAPSHOT_DATE = DATE_;
        COMMIT;
        
        INSERT INTO GET_LOAN_DIM_9M
        SELECT A.CUSTOMER_ID, A.SNAPSHOT_DATE, A.PERIOD_WINDOW,
                A.D1 AS D3,
                A.D5 AS D7,
                B.D19 AS D17,
                A.D23 AS D21,
                A.D27 AS D25,
                A.D31 AS D29,
                A.D35 AS D33,
                A.D39 AS D37,
                A.D43 AS D45,
                A.D47 AS D49,
                A.D51 AS D53,
                A.D55 AS D57,
                A.D59 AS D61,
                A.D67 AS D69,
                A.D71 AS D73,
                A.D75 AS D77,
                A.D79 AS D81,
                A.D83 AS D85,
                A.D87 AS D89,
                A.D91 AS D93,
                A.D95 AS D97,
                B.D103 AS D105,
                A.D107 AS D109,
                A.D119 AS D121,
                A.D123 AS D125,
                A.D128 AS D130,
                A.D132 AS D134,
                A.D136 AS D138,
                A.D140 AS D142,
                A.D144 AS D146,
                A.D160 AS D166,
                A.D161 AS D167,
                A.D162 AS D168
        FROM GET_LOAN_DIM_XXXM_SUMMARY A
        LEFT JOIN GET_LOAN_DIM_AVG_GR_RATE B
        ON A.CUSTOMER_ID = B.CUSTOMER_ID AND A.SNAPSHOT_DATE = B.SNAPSHOT_DATE AND A.PERIOD_WINDOW = B.PERIOD_WINDOW
        WHERE 1=1
        AND A.SNAPSHOT_DATE = DATE_
        ;
        COMMIT;
        PKG_LOGS.LOG('PKG_SUM_STG_LOAN_DIM', 'GET_LOAN_DIM_9M', DATE_, 'END');
        
    END GET_LOAN_DIM_9M;
    
    
    --- 7.
    PROCEDURE GET_LOAN_DIM_12M(DATE_ DATE) AS
        T NUMBER;
    BEGIN
        T := 12;
        PKG_LOGS.LOG('PKG_SUM_STG_LOAN_DIM', 'GET_LOAN_DIM_12M', DATE_, 'BEGIN');
        DELETE FROM GET_LOAN_DIM_12M WHERE SNAPSHOT_DATE = DATE_;
        COMMIT;
        
        INSERT INTO GET_LOAN_DIM_12M
        SELECT A.CUSTOMER_ID, A.SNAPSHOT_DATE, A.PERIOD_WINDOW,
                A.D1 AS D4,
                A.D5 AS D8,
                B.D19 AS D16,
                A.D23 AS D20,
                A.D27 AS D24,
                A.D31 AS D28,
                A.D35 AS D32,
                A.D39 AS D36,
                A.D43 AS D46,
                A.D47 AS D50,
                A.D51 AS D54,
                A.D55 AS D58,
                A.D59 AS D62,
                A.D67 AS D70,
                A.D71 AS D74,
                A.D75 AS D78,
                A.D79 AS D82,
                A.D83 AS D86,
                A.D87 AS D90,
                A.D91 AS D94,
                A.D95 AS D98,
                B.D103 AS D106,
                A.D107 AS D110,
                A.D119 AS D122,
                A.D123 AS D126,
                A.D128 AS D131,
                A.D132 AS D135,
                A.D136 AS D139,
                A.D140 AS D143,
                A.D144 AS D147,
                A.D160 AS D13,
                A.D161 AS D14,
                A.D162 AS D15
        FROM GET_LOAN_DIM_XXXM_SUMMARY A
        LEFT JOIN GET_LOAN_DIM_AVG_GR_RATE B
        ON A.CUSTOMER_ID = B.CUSTOMER_ID AND A.SNAPSHOT_DATE = B.SNAPSHOT_DATE AND A.PERIOD_WINDOW = B.PERIOD_WINDOW
        WHERE 1=1
        AND A.SNAPSHOT_DATE = DATE_
        ;
        COMMIT;
        PKG_LOGS.LOG('PKG_SUM_STG_LOAN_DIM', 'GET_LOAN_DIM_12M', DATE_, 'END');
        
    END GET_LOAN_DIM_12M;
    
    --- 8.
    PROCEDURE TRUNC_TEMP_TABS AS
    BEGIN
        PKG_LOGS.LOG('PKG_SUM_STG_LOAN_DIM', 'TRUNC_TEMP_TABS', NULL, 'BEGIN');
        
        EXECUTE IMMEDIATE 'TRUNCATE TABLE GET_LOAN_DIM_TIME_WINDOW';
        EXECUTE IMMEDIATE 'TRUNCATE TABLE GET_LOAN_DIM_1M_LAG';
        EXECUTE IMMEDIATE 'TRUNCATE TABLE GET_LOAN_DIM_XXXM_SUMMARY';
        EXECUTE IMMEDIATE 'TRUNCATE TABLE GET_LOAN_DIM_AVG_GR_RATE';
        
        PKG_LOGS.LOG('PKG_SUM_STG_LOAN_DIM', 'TRUNC_TEMP_TABS', NULL, 'END');
    END TRUNC_TEMP_TABS;
    
END PKG_SUM_STG_LOAN_DIM;