/*Create scripts of tables:*/

create table accounts(Account_ID varchar2(100),Admit_Date varchar2(50),Attending_Provider_ID varchar2(100),	
Discharge_Date	varchar2(50), Discharge_Year varchar2(50),	Facility_Code varchar2(6),	LOS number, MS_DRG_Code number,	Patient_ZipCode number);

create table Diagnosis( Account_ID varchar2(100), Diagnosis_Code varchar(100),	Diagnosis_Sequence number);

create table charges(Account_ID varchar2(100),	Charge_Code number,	Charge_Department_Code	varchar2(20), Service_Date varchar2(50),
Posting_Date varchar2(50), Charge_Transaction_ID number,	Total_Charges number);

create table lookup_table_charge(Charge_Code number,	Charge_Description varchar2(100));

create table lookup_table_diagnosis(Diagnosis_Code varchar(100),	Diagnosis_Description varchar(100),	Dx_Clinical_Classification varchar(300));

create table lookup_table_facility(Facility_Code varchar2(6),	Facility_Name varchar(250));

create table lookup_table_MS_DRG_Service_Line(MS_DRG_Code number,	Service_Line_Description varchar(250));

create table lookup_table_MS_DRG(MS_DRG_Code number,	MS_DRG varchar(300),	MS_DRG_Description	varchar(300),
CMS_MS_DRG_Weight number,	Geometric_Mean_LOS	number, Arithmetic_Mean_LOS number);

create table lookup_table_provider(Provider_ID varchar2(100),	Provider_name  varchar(250),	Provider_Service varchar(250));



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


/* Q2. Which diagnosis related groups (MS-DRGs) have the highest average charges per patient account?*/

--select avg(total_charges) from charges  where account_id='A_0003457720';
----3397.766666666666666666666666666666666667
--1-account-1-msdrg
--
--select avg(total_charges) from charges  where account_id='A_0002892449';--1875
--
--select * from accounts where account_id='A_0003457720';--order by 1;

select avg(c.total_charges) as avg_total_charges,c.account_id,a.ms_drg_code,lkp_drg.MS_DRG_Description from accounts a  
join charges c on a.Account_ID = c.Account_ID 
join
    lookup_table_MS_DRG lkp_drg ON a.MS_DRG_Code = lkp_drg.MS_DRG_Code
group by c.account_id,a.ms_drg_code,lkp_drg.MS_DRG_Description
order by avg_total_charges desc
fetch first 10 rows only;


--
--SELECT a.ms_drg_code,
--    AVG(c.Total_Charges) AS Avg_Charges_Per_Account
--FROM
--    Accounts a
--JOIN
--    Charges c ON a.Account_ID = c.Account_ID
--GROUP BY
--    a.ms_drg_code
--ORDER BY
--    Avg_Charges_Per_Account DESC;
--    
--    
--select * from accounts where ms_drg_code=512;
--    
--select * from lookup_table_MS_DRG where ms_drg_code=203;
--203

/* Q3. Which Attending Provider Service had the highest volume of accounts (encounters) during December 2018?*/



SELECT COUNT(a.account_id) AS account_count, MAX(lkp_ap.Provider_Service) AS Provider_Service
FROM accounts a
JOIN lookup_table_provider lkp_ap ON a.Attending_Provider_ID = lkp_ap.Provider_ID
WHERE TO_CHAR(TO_DATE(admit_date,'YYYY-MM-DD'),'YYYY-MM') = '2018-12'
GROUP BY a.Attending_Provider_ID
ORDER BY account_count DESC
FETCH FIRST 1 ROW ONLY;

--select count(account_id), Attending_Provider_ID from accounts
--WHERE TO_CHAR(TO_DATE(admit_date,'YYYY-MM-DD'),'YYYY-MM') = '2018-12'
--group by Attending_Provider_ID
--order by 1 desc;


--select * from lookup_table_provider where provider_id=
--'PHY_003777';


--select * from lookup_table_provider where Provider_ID='PHY_003777';--Internal Medicine


/* Q4. What is the “average length of stay” (number of hospital days between admit date and discharge date, 
but not including discharge date) for each of the 4 facilities for each of the years for which account information are provided
(2018 & 2019).*/

--LOS includes the discharge date, so would have to do -1
--SELECT 
--    Facility_Name,
--    EXTRACT(YEAR FROM TO_DATE(Admit_Date, 'YYYY-MM-DD')) AS Year,
--    AVG(TO_DATE(Discharge_Date, 'YYYY-MM-DD') - TO_DATE(Admit_Date, 'YYYY-MM-DD') - 1) AS Average_Length_of_Stay,
--    AVG(LOS)-1
--FROM 
--    accounts a
--JOIN 
--    lookup_table_facility f ON a.Facility_Code = f.Facility_Code
--WHERE 
--    Discharge_Year IN ('2018', '2019')
--GROUP BY 
--    Facility_Name, EXTRACT(YEAR FROM TO_DATE(Admit_Date, 'YYYY-MM-DD'))
--ORDER BY 
--    Facility_Name, Year;
--
--
--select * from accounts;

    
SELECT 
    ROUND(AVG(CASE 
                 WHEN a.Discharge_Date != a.Admit_Date THEN a.LOS - 1
                 ELSE a.LOS
             END), 2) AS avg_length_of_stay,
    lkp_fclty.Facility_Name,
    EXTRACT(YEAR FROM TO_DATE(a.Admit_Date, 'YYYY-MM-DD')) AS year
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
    lkp_fclty.Facility_Name, year;


--select * from lookup_table_facility;

--select * from accounts a;--F_0120
--F_0116
--F_0117
--F_0119

/* Q5. Which MS-DRGs Service Lines had the largest difference between the observed
length of stay and the national average provided in the MS-DRG reference file? 
Use the "Arithmetic Mean LOS" field as the national average.*/


SELECT
    drg.Service_Line_Description,
    ROUND(AVG(a.LOS),2) AS observed_avg_length_of_stay,
    ref.Arithmetic_Mean_LOS as  national_average,
    round(ABS(AVG(a.LOS) - ref.Arithmetic_Mean_LOS),2) AS difference
FROM
    accounts a
JOIN
    lookup_table_MS_DRG_Service_Line drg ON a.MS_DRG_Code = drg.MS_DRG_Code
JOIN
    lookup_table_MS_DRG ref ON a.MS_DRG_Code = ref.MS_DRG_Code
GROUP BY
    drg.Service_Line_Description,
    ref.Arithmetic_Mean_LOS
ORDER BY
    difference DESC
    fetch first 10 rows only;


/*Q6. How did the monthly patient admissions vary between the years 2018 and 2019? to plan */

SELECT
    EXTRACT(MONTH FROM TO_DATE(admit_date, 'YYYY-MM-DD')) AS month,
    EXTRACT(YEAR FROM TO_DATE(admit_date, 'YYYY-MM-DD')) AS year,
    COUNT(*) AS patient_count
FROM
    accounts
WHERE
    EXTRACT(YEAR FROM TO_DATE(admit_date, 'YYYY-MM-DD')) IN (2018, 2019)
GROUP BY
    EXTRACT(MONTH FROM TO_DATE(admit_date, 'YYYY-MM-DD')),
    EXTRACT(YEAR FROM TO_DATE(admit_date, 'YYYY-MM-DD'))
ORDER BY
    year, month;
