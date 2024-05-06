

/* Q1. For accounts discharged during 2019, which were the most common primary diagnoses? Secondary diagnoses?*/
--Primary diagnosis
select a.diagnosis_code||' ('||lkp_d.Diagnosis_Description||')',a.frequency from (
SELECT COUNT(d.diagnosis_code) AS Frequency, d.diagnosis_code
FROM diagnosis d
JOIN accounts a ON d.account_id = a.account_id
WHERE d.diagnosis_sequence = 1 AND a.discharge_year= 2019
GROUP BY d.diagnosis_code
ORDER BY Frequency DESC
FETCH FIRST 10 ROWS ONLY) a
join lookup_table_diagnosis lkp_d
on a.diagnosis_code=lkp_d.diagnosis_code;
/*
OUTPUT:
CODE DESCRIPTION FREQUENCY
Z38.00 (Single liveborn infant, delivered vaginally)	74
A41.9 (Sepsis, unspecified organism)	51
Z38.01 (Single liveborn infant, delivered by cesarean)	48
J18.9 (Pneumonia, unspecified organism)	40
J44.1 (Chronic obstructive pulmonary disease w (acute) exacerbation)	35
N39.0 (Urinary tract infection, site not specified)	32
M17.9 (Osteoarthritis of knee, unspecified)	30
I48.91 (Unspecified atrial fibrillation)	29
O48.0 (Post-term pregnancy)	21
R07.82 (Intercostal pain)	21
*/

--Secondary diagnosis
select a.diagnosis_code||' ('||lkp_d.Diagnosis_Description||')',a.frequency from (
SELECT COUNT(d.diagnosis_code) AS Frequency, d.diagnosis_code
FROM diagnosis d
JOIN accounts a ON d.account_id = a.account_id
WHERE d.diagnosis_sequence <> 1 AND a.discharge_year= 2019
GROUP BY d.diagnosis_code
ORDER BY Frequency DESC
FETCH FIRST 10 ROWS ONLY) a
join lookup_table_diagnosis lkp_d
on a.diagnosis_code=lkp_d.diagnosis_code;

/*
OUTPUT:
CODE DESCRIPTION FREQUENCY
I10 (Essential (primary) hypertension)	775
Z87.891 (Personal history of nicotine dependence)	550
E78.4 (Other hyperlipidemia)	473
I25.10 (Athscl heart disease of native coronary artery w/o ang pctrs)	355
K21.9 (Gastro-esophageal reflux disease without esophagitis)	353
E11.9 (Type 2 diabetes mellitus without complications)	258
I48.91 (Unspecified atrial fibrillation)	224
E03.9 (Hypothyroidism, unspecified)	207
J44.9 (Chronic obstructive pulmonary disease, unspecified)	198
F17.200 (Nicotine dependence, unspecified, uncomplicated)	195
*/


/* Q2. Which diagnosis related groups (MS-DRGs) have the highest average charges per patient account?*/

SELECT 
    AVG(account_total_charges) AS avg_total_charges,
    a.ms_drg_code,
    lkp_drg.MS_DRG_Description
FROM 
    accounts a
JOIN (
    SELECT 
        Account_ID,
        SUM(total_charges) AS account_total_charges
    FROM 
        charges
    GROUP BY 
        Account_ID
)  c ON a.Account_ID = c.Account_ID
JOIN lookup_table_MS_DRG lkp_drg ON a.MS_DRG_Code = lkp_drg.MS_DRG_Code
GROUP BY 
    a.ms_drg_code,
    lkp_drg.MS_DRG_Description
ORDER BY 
    avg_total_charges DESC
FETCH FIRST 10 ROWS ONLY;

/*
OUTPUT:
AVG_TOTAL_CHARGES MS_DRG_CODE MS_DRG_DESCRIPTION
630043.3966666666666666666666666666666667	4	TRACHEOSTOMY WITH MV >96 HOURS OR PRINCIPAL DIAGNOSIS EXCEPT FACE, MOUTH AND NECK WITHOUT MAJOR O.R. PROCEDURES
448226.595	3	ECMO OR TRACHEOSTOMY WITH MV >96 HOURS OR PRINCIPAL DIAGNOSIS EXCEPT FACE, MOUTH AND NECK WITH MAJOR O.R. PROCEDURES
420861.48	652	KIDNEY TRANSPLANT
321572.91	915	ALLERGIC REACTIONS WITH MCC
291848.07	266	ENDOVASCULAR CARDIAC VALVE REPLACEMENT AND SUPPLEMENT PROCEDURES WITH MCC
220603.875	226	CARDIAC DEFIBRILLATOR IMPLANT WITHOUT CARDIAC CATHETERIZATION WITH MCC
194860.9833333333333333333333333333333333	957	OTHER O.R. PROCEDURES FOR MULTIPLE SIGNIFICANT TRAUMA WITH MCC
194220.29	207	RESPIRATORY SYSTEM DIAGNOSIS WITH VENTILATOR SUPPORT >96 HOURS
192954.16	25	CRANIOTOMY AND ENDOVASCULAR INTRACRANIAL PROCEDURES WITH MCC
190332.06	224	CARDIAC DEFIBRILLATOR IMPLANT WITH CARDIAC CATHETERIZATION WITHOUT AMI, HF OR SHOCK WITH MCC
*/
/* Q3. Which Attending Provider Service had the highest volume of accounts (encounters) during December 2018?*/

SELECT 
    COUNT(a.account_id) AS account_count,
    lkp_ap.Provider_Service
FROM 
    accounts a
JOIN 
    lookup_table_provider lkp_ap ON a.Attending_Provider_ID = lkp_ap.Provider_ID
WHERE 
    TO_CHAR(TO_DATE(admit_date,'YYYY-MM-DD'),'YYYY-MM') = '2018-12'
GROUP BY 
    lkp_ap.Provider_Service
ORDER BY 
    account_count DESC
FETCH FIRST 5 ROWS ONLY;
/*
OUTPUT:
77	Internal Medicine
30	Family Medicine
19	Pediatrics
9	OB/Gyn
9	NULL
/*


------WHY NULL VALUE
select * from accounts where account_id ='A_0003557533';
select * from lookup_table_provider where Provider_ID='PHY_026223';
---PHY_026223	Vaughn, Y	null



/* Q4. What is the “average length of stay” (number of hospital days between admit date and discharge date, 
but not including discharge date) for each of the 4 facilities for each of the years for which account information are provided
(2018 & 2019).*/

SELECT 
    lkp_fclty.Facility_Name,
    EXTRACT(YEAR FROM TO_DATE(a.Admit_Date, 'YYYY-MM-DD')) AS year,
    SUM(CASE 
            WHEN a.Discharge_Date != a.Admit_Date THEN a.LOS - 1
            ELSE a.LOS
        END) AS total_length_of_stay,
    ROUND(AVG(CASE 
                 WHEN a.Discharge_Date != a.Admit_Date THEN a.LOS - 1
                 ELSE a.LOS
             END), 2) AS avg_length_of_stay
FROM 
    accounts a 
JOIN 
    lookup_table_facility lkp_fclty ON a.Facility_Code = lkp_fclty.Facility_Code
WHERE 
    TO_NUMBER(TO_CHAR(TO_DATE(a.Admit_Date, 'YYYY-MM-DD'), 'YYYY')) IN (2018, 2019)
GROUP BY 
    lkp_fclty.Facility_Name,
    EXTRACT(YEAR FROM TO_DATE(a.Admit_Date, 'YYYY-MM-DD'))
ORDER BY 
    avg_length_of_stay DESC,lkp_fclty.Facility_Name, year;

/*
OUTPUT:
FACILITY_NAME YEAR TOTAL_LENGTH_OF_STAY AVG_LENGTH_OF_STAY
SPRINGFIELD HOSPITAL	2019	1345	4.05
SPRINGFIELD HOSPITAL	2018	1165	3.98
TRINITY HOSPITAL	2019	1838	3.49
MAPLEWOOD HOSPITAL	2018	1244	3.45
TRINITY HOSPITAL	2018	1588	3.16
MAPLEWOOD HOSPITAL	2019	994	2.82
LONGWOOD	2018	1466	2.77
LONGWOOD	2019	1507	2.7
*/

/* Q5. Which MS-DRGs Service Lines had the largest difference between the observed
length of stay and the national average provided in the MS-DRG reference file? 
Use the "Arithmetic Mean LOS" field as the national average.*/

--Approach 1: using Arithmetic Mean LOS as national average
WITH LOS AS (
    SELECT 
        a.account_id,
       -- a.ms_drg_code,
        CASE 
            WHEN a.Discharge_Date != a.Admit_Date THEN a.LOS - 1
            ELSE a.LOS
        END AS LOS
    FROM 
        accounts a)
SELECT 
   --s.ms_drg_code,
    s.service_line_description,
    MAX(ABS((SELECT AVG(L.LOS) FROM LOS L) - d.Arithmetic_Mean_LOS)) AS difference
    --MAX(ABS((SELECT AVG(LOS) FROM accounts) - d.Arithmetic_Mean_LOS)) AS difference 
   -- ABS(AVG(a.LOS) - d.Arithmetic_Mean_LOS) AS difference 
FROM 
    lookup_table_MS_DRG_Service_Line s 
JOIN 
    accounts a ON s.ms_drg_code = a.ms_drg_code 
JOIN 
    lookup_table_MS_DRG d ON d.ms_drg_code = a.ms_drg_code 
GROUP BY
    s.service_line_description--,s.ms_drg_code
ORDER BY 
    difference DESC
fetch first 10 rows only;

/*
Output:
service_line_description difference
SURGICAL TRACHEOSTOM	26.92510074841681059297639608520437535982
ONCOLOGY/HEMATOLOGY	13.32510074841681059297639608520437535982
OPEN HEART	11.42510074841681059297639608520437535982
GENERAL MEDICINE	11.22510074841681059297639608520437535982
PULMONARY	10.72510074841681059297639608520437535982
OTHER ORTHOPAEDICS	10.12510074841681059297639608520437535982
NEONATOLOGY	10.02510074841681059297639608520437535982
VASCULAR SURGERY	9.92510074841681059297639608520437535982
OTHER	9.82510074841681059297639608520437535982
GENERAL SURGERY	9.72510074841681059297639608520437535982
*/

/*
---When group it according to MS_DRG_CODE I have 2 results
ms_drg_code service_line_description difference
3	SURGICAL TRACHEOSTOM	26.92510074841681059297639608520437535982
4	SURGICAL TRACHEOSTOM	21.32510074841681059297639608520437535982
834	ONCOLOGY/HEMATOLOGY	13.32510074841681059297639608520437535982
216	OPEN HEART	11.42510074841681059297639608520437535982
870	GENERAL MEDICINE	11.22510074841681059297639608520437535982
207	PULMONARY	10.72510074841681059297639608520437535982
11	SURGICAL TRACHEOSTOM	10.52510074841681059297639608520437535982
463	OTHER ORTHOPAEDICS	10.12510074841681059297639608520437535982
791	NEONATOLOGY	10.02510074841681059297639608520437535982
239	VASCULAR SURGERY	9.92510074841681059297639608520437535982
*/
    
    
--Approach 2: AVG of national avg: Highest is 18.325
WITH LOS AS (
    SELECT 
    MS_DRG_Code,
        Account_ID,
        CASE 
            WHEN Discharge_Date != Admit_Date THEN LOS - 1 
            ELSE LOS 
        END AS LOS
    FROM 
        accounts
)
SELECT 
    s.Service_Line_Description,
    ABS(AVG(l.LOS) - AVG(d.Arithmetic_Mean_LOS)) AS Difference
FROM 
    LOS l
JOIN 
    lookup_table_MS_DRG_Service_Line s ON l.MS_DRG_Code = s.MS_DRG_Code
JOIN 
    lookup_table_MS_DRG d ON l.MS_DRG_Code = d.MS_DRG_Code
GROUP BY 
    s.Service_Line_Description
ORDER BY 
    Difference DESC
    fetch first 10 rows only;
/*   
Output:
service_line_description difference
SURGICAL TRACHEOSTOM	18.325
PSYCHIATRY	2.68292682926829268292682926829268292683
NORMAL NEWBORN	2.08384279475982532751091703056768558952
OTHER OB	2.07142857142857142857142857142857142857
NEONATOLOGY	1.79310344827586206896551724137931034482
CARDIAC CATHS	1.67647058823529411764705882352941176471
OBSTETRICS	1.48190789473684210526315789473684210526
NEUROLOGY	1.36746987951807228915662650602409638554
OPEN HEART	1.35128205128205128205128205128205128205
ONCOLOGY/HEMATOLOGY	1.21428571428571428571428571428571428571
*/

