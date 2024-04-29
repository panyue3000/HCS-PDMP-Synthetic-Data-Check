
title; footnote; libname _all_; filename _all_;
proc datasets library=work memtype=data kill; quit; run;
ods graphics off;


options mergenoby=error;
%let rundate = %sysfunc(today(),yymmddn8.);


/********************************************************************************************************************/
/**************************Set the export path for the final dataset of counts by community**************************/
/********************************************************************************************************************/

%let export_path = C:\Users\panyue\Box\1 Healing Communities\Data Issues\1 1 1 1 Wave 2\Synthetic Data\PMP Measures;

/************************************************************************************************************************/
/************************************************************************************************************************/
/************************************************************************************************************************/


/**************************************************************************************************************/
/**************************Set the import path for the NDC lists and define filenames**************************/
/**************************************************************************************************************/


%let import_path = C:\Users\panyue\Box\1 Healing Communities\Data Issues\1 1 1 1 Wave 2\Synthetic Data\Files;
%let bup_file = Merged_NDC_20220825.xlsx;
%let opioid_file = Merged_NDC_20220825.xlsx;
%let benzo_file = Merged_NDC_20220825.xlsx;

*LIBNAME pmplib '\\2UA64226CP\Healing PMP\DATA'; 
*LIBNAME fmtbasic '\\2UA64226CP\Healing PMP';
LIBNAME pmplib '\\doh-smb\doh_shared\Projects\BNE\BNE_SCRIPT_DATA\Data';
LIBNAME fmtbasic '\\doh-smb\doh_shared\Projects\BNE\BNE_SCRIPT_DATA';
libname test 'C:\Users\vxn09\Desktop\PMP Practice';
*LIBNAME  pdmplib '\\10.50.79.64\opioid\data';
%include "\\doh-smb\doh_shared\Projects\BNE\BNE_SCRIPT_DATA\CHIR_Format_new.sas";
*libname x '\\2UA64226CP\Healing PMP\DATA';
OPTIONS FMTSEARCH=(FMTBASIC.FORMATS) obs=max symbolgen mprint;
proc format library=fmtbasic cntlout=outfmt;
run;

proc format cntlin=outfmt;
run;


/*****************************************************************************************/
/*****************************************************************************************/
/*****************************************************************************************/


PROC IMPORT OUT= WORK.bup0
            DATAFILE= "&import_path/&bup_file" 
            DBMS=XLSX REPLACE;
     SHEET="Bup"; 
     GETNAMES=YES;
RUN;

proc sql;
create table bup as
select unique ndc_upc_hri as ndc_char label = 'ndc_char'
from bup0
where ndc_upc_hri ne '';
quit;

/*****************************************************************************************/

PROC IMPORT OUT= WORK.benzo0
            DATAFILE= "&import_path/&benzo_file" 
            DBMS=XLSX REPLACE;
     SHEET="Benzo"; 
     GETNAMES=YES;
RUN;

proc sql;
create table benzo as
select unique ndc_upc_hri as ndc_char label = 'ndc_char'
from benzo0
where ndc_upc_hri ne '';
quit;


/*****************************************************************************************/

/*PROC IMPORT OUT= WORK.opioid0
            DATAFILE= "&import_path/&opioid_file" 
            DBMS=XLSX REPLACE;
     SHEET="NDC"; 
     GETNAMES=YES;
RUN;

data opioid1;
set opioid0;

ndc_char = ndc_upc_hri;
mme_conversion_factor = mme;
strength_per_unit = strength_unit;

if long_short_acting = 'LA' then long_act = 1;
if long_short_acting = 'SA' then long_act = 0;

keep ndc_char 	 long_act 	 mme_conversion_factor 	 strength_per_unit;
run;
*/
PROC IMPORT OUT= WORK.opioid0
            DATAFILE= "&import_path/&opioid_file" 
            DBMS=XLSX REPLACE;
     SHEET="OP"; 
     GETNAMES=YES;
RUN;

data opioid1;
set opioid0;

ndc_char = ndc_upc_hri;
mme_conversion_factor = mme;
strength_per_unit = strength_unit;

if long_short_acting = 'LA' then long_act = 1;
if long_short_acting = 'SA' then long_act = 0;

keep ndc_char 	 long_act 	 mme_conversion_factor 	 strength_per_unit;
run;

proc sql;
create table opioid as 
select unique *
from opioid1;
quit;


/*********************************************************************************************/
/*********************************************************************************************/
/*********************************************************************************************/
/*Step A:Create macro variables that contain the start date and end date of the data being 
analyzed. If the beginning of the study period is January 1, 2018, the start date of the 
data analyzed should be July 1, 2017 because six months of records are needed for look-back. 
The end date should not exceed the date of the available complete PMP data.
/*********************************************************************************************/
%let start_date = mdy(07,01,2022);
%let end_date = mdy(12,31,2023);
/********************************************************************************************************************************************/
/*Create a dataset that has every date in the date range. This will be used below for a "call execute" to query each possible day separately*/
/********************************************************************************************************************************************/
data date_range;
do date=&start_date to &end_date;
output;
end;
format date date9.;
run;

data for_first_and_last;
set date_range;
month=month(date);
year=year(date);
run;

proc sort data=for_first_and_last; by year month date; run;

data first_and_last; set for_first_and_last; by year month date;
if not first.month and not last.month then delete;
drop month year;
run;
/*********************************************************************************************/
/*Step B: Create a table of HCS communities. Include any information you will need in order to */
/*join this table with the PMP data (ZIP codes, city/town names, county names, etc.).*/
/*********************************************************************************************/
data zip0;
set pmplib.zip;
keep fips county cos zipcode;
run;
PROC IMPORT OUT= WORK.HCS_zips1   DATAFILE= "T:\PHIG_documents\Grants\Prescription Drug Overdose - CDC Grant\Special Projects\HEALing\PMP\Zipcodes for 3 communities.xlsx" 
            DBMS=EXCEL REPLACE;
     RANGE="HCS_communities$"; 
     GETNAMES=YES;
     MIXED=NO;
     SCANTEXT=YES;
     USEDATE=YES;
     SCANTIME=YES;
RUN;
data hcs_zips2;
set HCS_zips1;
zip_char=put(ZIP_code,z5.);
hcs=1;
drop ZIP_code;
run;
proc sql;
create table all_zips as
select a.*, b.*
from zip0 as a 
left join hcs_zips2 as b
on a.zipcode=b.zip_char;
quit;
data zips;
set all_zips;
length community $100.;
community=county;
if county eq 'Suffolk' and town ne '' then community=town;
else if  county eq 'Suffolk' and town eq '' then community='Rest of Suffolk';
if county eq 'Erie' and town ne '' then community=town;
else if  county eq 'Erie' and town eq '' then community='Rest of Erie';
if county eq 'Monroe' and town ne '' then community=town;
else if  county eq 'Monroe' and town eq '' then community='Rest of Monroe';
zip_char=zipcode ;
hcs=1;
keep zipcode cos community 	zip_char hcs; run;

/*Only use for Measure 3.3 
if community in ("Broome", "Cayuga", "Chautauqua", "Columbia", "Cortland",  
"Genesee", "Greene", "Lewis",  "Orange", "Putnam",  "Sullivan", "Ulster", "Yates", 
 "Suffolk", "Erie", "Monroe", "Rochester", "Brookhaven Township", "Buffalo", "Rest of Erie",
"Rest of Monroe", "Rest of Suffolk");

run;

/********************************************************************************************************************************************/
/*Identify time periods that are fully included in the date range*/
/********************************************************************************************************************************************/
proc sql;
create table months0 as
select unique 	year(date) as year,
				month(date) as month,
				count(date) as days
from date_range
group by year, month;
quit;
proc sql;
create table quarters0 as
select unique 	year(date) as year, 
				qtr(date) as quarter, 
				count(date) as days
from date_range
group by year, quarter;
quit;
proc sql;
create table years0 as
select unique 	year(date) as year, 
				count(date) as days
from date_range
group by year;
quit;

data months;
set months0;
if month in (1,3,5,7,8,10,12) then do;
	if days lt 31 then complete = 0;
	if days eq 31 then complete = 1;
end;

if month in (4,6,9,11) then do;
	if days lt 30 then complete = 0;
	if days eq 30 then complete = 1;
end;


if month = 2 and mod(year,4) eq 0 then do;
	if days lt 29 then complete = 0;
	if days eq 29 then complete = 1;
end;

if month = 2 and mod(year,4) ne 0 then do;
	if days lt 28 then complete = 0;
	if days eq 28 then complete = 1;
end;
run;

data quarters;
set quarters0;
if quarter = 1 and mod(year,4) eq 0 then do; 
	if days lt 91 then complete = 0;
	if days eq 91 then complete = 1;
end;

if quarter = 1 and mod(year,4) ne 0 then do;
	if days lt 90 then complete = 0;
	if days eq 90 then complete = 1;
end;

if quarter = 2 then do;
	if days lt 91 then complete = 0;
	if days eq 91 then complete = 1;
end;

if quarter in (3,4) then do;  
	if days lt 92 then complete = 0;
	if days eq 92 then complete = 1;
end;
run;

data years;
set years0;
if mod(year,4) eq 0 then do; 
	if days lt 366 then complete = 0;
	if days eq 366 then complete = 1;
end;

if mod(year,4) ne 0 then do; 
	if days lt 365 then complete = 0;
	if days eq 365 then complete = 1;
end;

run;


/*create lists of all combinations of communities and time periods to assign zeros*/
proc sql;
create table all_possible_y as
select unique 	a.community, 
				b.year,
				b.complete
from zips a, years b
where b.year ge 2017
order by community, year;
quit;

proc sql;
create table all_possible_q as
select unique 	a.community,
				b.year,
				b.quarter,
				b.complete
from zips a, quarters b
where b.year ge 2017
order by community, year, quarter;
quit;

proc sql;
create table all_possible_m as
select unique 	a.community,
				b.year,
				b.month,
				b.complete
from zips a, months b
where b.year ge 2017
order by community, year, month;
quit;

/********************************************************************************************************;*/
/********************************************************************************************************;*/

/**NYS ADDITION: CREATE DATASET WITH UNIQUE AGE CATEGORIES, YEAR, AND GENDER FOR STRATIFICATION;*/

/********************************************************************************************************;*/
/********************************************************************************************************;*/
data age_cat0;
set all_possible_y;
age_cat=0;
run;
data age_cat1;
set all_possible_y;
age_cat=1;
run;
data age_cat2;
set all_possible_y;
age_cat=2;
run;
data age_cat3;
set all_possible_y;
age_cat=3;
run;
data all_possible_y_age;
set age_cat0 age_cat1 age_cat2 age_cat3;
run;
proc sort data=all_possible_y_age;
by community  year age_cat;
run;
data gender0;
set all_possible_y;
gender='0';
run;
data gender1;
set all_possible_y;
gender='1';
run;
data gender2;
set all_possible_y;
gender='2';
run;
data all_possible_y_gender;
set gender0 gender1 gender2;
run;
proc sort data=all_possible_y_gender;
by community  year gender;
run;
proc sql;
create table all_possible_y_state as
select unique year,	complete, "New York State" as community length = 100
from  years 
order by community, year;
quit;
data stgender0;
set all_possible_y_state;
gender='0';
run;
data stgender1;
set all_possible_y_state;
gender='1';
run;
data stgender2;
set all_possible_y_state;
gender='2';
run;
data all_possible_y_gender_st;
set stgender0 stgender1 stgender2;
run;
proc sort data=all_possible_y_gender_st;
by community  year gender;
run;
data stage0;
set all_possible_y_state;
age_cat=0;
run;
data stage1;
set all_possible_y_state;
age_cat=1;;
run;
data stage2;
set all_possible_y_state;
age_cat=2;;
run;
data stage3;
set all_possible_y_state;
age_cat=3;;
run;
data all_possible_y_age_st;
set stage0 stage1 stage2 stage3;
run;
proc sort data=all_possible_y_age_st;;
by community  year age_cat;
run;


/*********************************************************************************************/
/*******************************************************************************************/
/*Step C: From the PMP database, select the IDs of all patients who filled a prescription***/
/*while a resident of an HCS community between the dates defined in step A. ****************/
/*******************************************************************************************/

/*proc sql;*/
/*create table pmp_hcs_temp as*/
/*select unique a.patientid as patient_id label = 'Patient ID' ,*/
/*			  a.filldate as date_filled format date9. label = 'Date filled',*/
/*			  b.community*/
/*from pmp1617 as a */
/*left join zips as b*/
/*on  a.patzip = b.zip_char and */
/*	  a.filldate ge &start_date and */
/*	  a.filldate le &end_date ;*/
/*quit;*/
/*********************************************************************************************/
/*Read in PMP data*/

/*   DAN THIS IS WHERE WE WOULD ADD THE SYNTHETIC DATA*/
/*********************************************************************************************/

data pmp_all;
set  pmplib.healingpmp2022 pmplib.healingpmp2023  ;
length patient_id $100. ;
patient_id=put(patientid,12.);
if patient_subset=1;
if vet=0;
where filldate ge &start_date and filldate le &end_date;
run;
proc sql;
create table pmp_hcs_temp as
select unique a.patient_id label = 'Patient ID' ,
			  a.filldate as date_filled format date9. label = 'Date filled',
			  b.community
from pmp_all a, zips b
where a.patzip = b.zip_char ;
quit;
proc sql;
create table pmp_hcs_ids as
select unique patient_id 
from pmp_hcs_temp;
quit;


/*****************************************************************************/
/*Step D: Select all PMP records of the patients selected in step C,**********/
/*regardless of the residence on the individual records.**********************/
/*****************************************************************************/
/*data pmp_all; */
/*set pmp_all;*/
/*patient_id = put(patientid,9.);*/
/*run;*/
proc sort data=pmp_all; by patient_id; run;
proc sort data=pmp_hcs_ids; by patient_id; run;


data all_records_step_d;
length patient_id $100;
merge pmp_hcs_ids (in=a) pmp_all (in=b); by patient_id;
if a and b;

*patient_id = uid;
date_filled = filldate;
year_filled = year(filldate);
quarter_filled = qtr(filldate);
month_filled = month(filldate);
/*new 20200625*/ /*?*/
date_written = DATE_RX_WRITTEN; 
year_written = year(DATE_RX_WRITTEN);
month_written = month(DATE_RX_WRITTEN);
/**************/
zip_char = patzip;
dob_inc_missing = PATIENT_BIRTH_DATE;
ndc11_char = ndcnum;
dea_prescriber = deano;
dea_pharmacy = pharmacy; 
quantity_dispensed = QUANTITY_DISPENSED;
days_dispensed =dayssupply;
date_run_out = (date_filled + (days_dispensed - 1));
gender=gender;

label patient_id = 'Patient ID';
label date_filled = 'Date filled';
label year_filled  = 'Year filled';
label quarter_filled = 'Quarter filled';
label month_filled  = 'Month filled';
/*new 20200625*/
label date_written = 'Date written';
label year_written  = 'Year written';
label month_written  = 'Month written';
/**************/
label zip_char = 'ZIP code';
label dob_inc_missing = 'DOB (including missing values)';
label ndc11_char = 'NDC';
label dea_prescriber = 'Prescriber DEA number';
label dea_pharmacy = 'Pharmacy DEA number';
label quantity_dispensed = 'Quantity dispensed';
label days_dispensed = 'Days dispensed';
label date_run_out = 'Run-out date';
label  gender ='Gender' ;

format date_filled date_run_out date_written date9.;

if date_filled lt &start_date then delete;
if date_filled gt &end_date then delete;

keep 
patient_id
date_filled 
year_filled 
quarter_filled 
month_filled 
/*new 20200625*/
date_written
year_written
month_written
/**************/
zip_char 
dob_inc_missing 
ndc11_char
dea_prescriber 
dea_pharmacy 
quantity_dispensed
days_dispensed 
date_run_out
gender;

run;

/********************************************************************************************************************************************/
/*Step E. Select unique combinations of patient ID and date of birth from the table created in step D where date of birth */
/*is not null. For each patient ID, keep one record with the most frequent date of birth for that patient. */
/*Using this date of birth throughout will enable us to use records with missing dates of birth and to avoid deleting */
/*records with date of birth typos or a missing date of birth. */
/********************************************************************************************************************************************/

proc sql;
create table pmp_dobs_temp as 
select unique 	patient_id ,
				dob_inc_missing as dob label = 'Date of birth', 
				count(dob) as dob_frequency
from all_records_step_d
where dob_inc_missing ge mdy(01,01,1900)
group by patient_id, dob
order by patient_id, dob_frequency desc, dob desc;
quit;

data pmp_dobs; set pmp_dobs_temp; by patient_id descending dob_frequency descending dob;
if not first.patient_id then delete;

year_18yo = 18 + year(dob);
qtr_dob = qtr(dob);
month_dob = month(dob);

drop dob_frequency;
run;
*NYS ADDITION : ADD GENDER TO THE TEMP DATA;
proc sql;
create table pmp_gender_temp as 
select unique 	patient_id ,
				gender as gender label = 'Gender', 
				count( gender) as gender_frequency
from all_records_step_d
where dob_inc_missing ge mdy(01,01,1900)
group by patient_id, gender
order by patient_id, gender_frequency desc, gender desc;
quit;
data pmp_gender; 
set pmp_gender_temp; 
by patient_id descending gender_frequency descending gender;
if not first.patient_id then delete;
drop gender_frequency;
run;
proc sql;
create table pmp_gender_dob as
select a.* , b.* 
from pmp_dobs a, pmp_gender b
where 	a.patient_id = b.patient_id;
quit;
/********************************************************************************************************************************************/
/********************************************************************************************************************************************/
/********************************************************************************************************************************************/
/*********************************************************************************************************************************/
/*Step F.Join the tables created in steps D and E. Calculate the age of the patient on the date of each prescription fill. */
/*Delete records where the patient is younger than 17 years of age. Also delete records where the patient is younger */
/*than 18 years of age on the end date defined in step A. Calculate the month and year in which each patient turned */
/*18 years of age. Results below will be calculated for patients =18 years of age in the month that is being evaluated. */
/*The records from the year in which patients are 17 years of age will be used for look-back.*/
/*********************************************************************************************************************************/

*NYS ADDITION: pmp_gender_dob dataset is used instead of pmp_dobs to include gender ;
proc sql;
create table all_records_step_f as
select 	a.*,  
		b.dob,
		b.year_18yo,
		b.qtr_dob,
		b.month_dob,
		b.gender,
		int(yrdif(b.dob, a.date_filled,'ACTUAL')) as age_at_fill,
		substr(a.ndc11_char,8,4) as ndc_last_4digits
from all_records_step_d a, pmp_gender_dob b
where 	a.patient_id = b.patient_id and 
		int(yrdif(b.dob, a.date_filled,'ACTUAL')) ge 17 ;
quit;
/*Step G.	From records with non-missing residences in the table created in step F, for each patient in each month */
/*that the patient filled a prescription, select the patient ID, month of the fill, quarter of the fill, year */
/*of the fill, and the patient's residence associated with their final fill (latest fill date) in each month. */
/*Select residences regardless of whether or not they are HCS communities. */
/**/
/*If a patient has two or more fills on the patient's last fill date of the month and those fills are associated */
/*with two or more residences, select the first record when sorting by the following variables:*/
/* */
/*a.	Descending binary variable that indicates if the residence is an HCS community (giving preference to HCS communities over non-HCS communities).*/
/*b.	Descending days supplied (giving preference to records with greater days supplied)*/
/*c.	Ascending NDC number*/
/*d.	Ascending prescriber DEA number*/
/**/
/*This residence is each patient's final residence for each month, regardless of whether or not it is an HCS community.*/

/***************************************************************************************************************************************************************/
/***************************************************************************************************************************************************************/
/***************************************************************************************************************************************************************/

proc sort data=all_records_step_f; by zip_char; run;
proc sort data=zips; by zip_char; run;

data step_g_temp1; merge all_records_step_f(in=a) zips (in=b); by zip_char; 
if a;
if not b then do;
	hcs = 0;
	community = '***NOT AN HCS COMMUNITY';
end;
run;
/*  DAN This step may need to be commmented out--not sure we will have Zips in thier file
*/

data step_g_temp2;
set step_g_temp1;
if zip_char in ('','99999') then delete; /*delete observations with missing zips, just for this step where we're selecting residences*/
run;

proc sort data=step_g_temp2; 
by 	patient_id 
	year_filled 
	month_filled 
	descending date_filled 
	descending hcs
	descending days_dispensed
	ndc_last_4digits
	dea_prescriber;
run;

data step_g_temp3;
set step_g_temp2;
by 	patient_id 
	year_filled 
	month_filled 
	descending date_filled 
	descending hcs
	descending days_dispensed
	ndc_last_4digits
	dea_prescriber;
if not first.month_filled then delete;
run;

proc sql;
create table step_g_temp4 as
select unique patient_id, 
			  year_filled as year, 
			  quarter_filled as quarter,
			  month_filled as month,
			  community,
			  hcs
from step_g_temp3;
quit;

/*proc contents data=step_g_temp4; run;*/


/*New in version 13.*/
/*Filling in prior last non-missing residence */
/*in months where a patient does not fill a prescription.*/


proc sql;
create table all_possible_id_month
as select a.patient_id,
			b.year,
			b.month
from pmp_hcs_ids a, months b
order by a.patient_id, b.year, b.month;
quit;


data step_g_temp5; merge all_possible_id_month step_g_temp4; by patient_id year month; 

if month in (1,2,3) then quarter = 1;
if month in (4,5,6) then quarter = 2;
if month in (7,8,9) then quarter = 3;
if month in (10,11,12) then quarter = 4;

run;

proc sort data=step_g_temp5; by patient_id year month; run;

data step_g_step6; set step_g_temp5; by patient_id year month; 
retain _community _hcs;

if first.patient_id then _community = community;
if not missing(community) then _community=community;
else community = _community;

if first.patient_id then _hcs = hcs;
if not missing(hcs) then _hcs=hcs;
else hcs = _hcs;

drop _community _hcs;

run;

data step_g; set step_g_step6; 
if community = '' then delete;
run;

proc datasets NOLIST;
	delete step_g_temp1 step_g_temp2 step_g_temp3 step_g_temp4 step_g_temp5 step_g_step6;
quit;


/*Step H.	From the table generated in step G, select the patient ID and residence for the maximum available */
/*month in each calendar quarter (e.g. if a patient filled prescriptions in January 2018 and February 2018*/
/*but not in March 2018, the February 2018 residence will be the Q1 2018 residence). These residences reflect */
/*each patient's final residence for each quarter, regardless of whether or not it is an HCS community.*/


proc sql;
create table step_h_temp as 
select 	patient_id,
		year,
		quarter,
		max(month) as max_month_in_quarter
from step_g
group by patient_id, year, quarter;
quit;

proc sql;
create table step_h as
select 	a.patient_id,
		a.year,
		a.quarter,
		a.community,
		a.hcs
from step_g a, step_h_temp b
where 	a.patient_id = b.patient_id and 
		a.year = b.year and
		a.quarter = b.quarter and 
		a.month = b.max_month_in_quarter;
quit;


/*Step I. From the table generated in step G, select the patient ID, residence combination for the maximum available */
/*month of each year. This residence reflects each patient's final residence for each year, regardless of whether */
/*or not it is an HCS community.*/


proc sql;
create table step_i_temp as 
select 	patient_id,
		year,
		max(month) as max_month_in_year
from step_g
group by patient_id, year;
quit;

proc sql;
create table step_i as
select 	a.patient_id,
		a.year,
		a.community,
		a.hcs
from step_g a, step_i_temp b
where 	a.patient_id = b.patient_id and 
		a.year = b.year and
		a.month = b.max_month_in_year;
quit;



/*Step J. From the table created in step G, delete the rows where the patient's residence is not an HCS community. */
/*The remaining monthly residences will be used when the patient is included in monthly counts. */
data step_j; set step_g; where hcs = 1; drop hcs; run;

/*Step K. From the table created in step H, delete the rows where the patient's residence is not an HCS community. */
/*The remaining quarterly residences will be used when the patient is included in quarterly counts.*/
data step_k; set step_h; where hcs = 1; drop hcs; run;

/*Step L. From the table created in step I, delete the rows where the patient's residence is not an HCS community. */
/*The remaining yearly residences will be used when the patient is included in yearly counts.*/
data step_L; set step_i; where hcs = 1; drop hcs; run;

/**************************************************************************************************************************************************/
/*Step M. From the table created in step F, use the HCS Approved dataset to select all filled prescriptions for buprenorphine */
/*or buprenorphine/naloxone products approved by the FDA for treatment of OUD. Exclude transdermal buprenorphine and Belbuca */
/*as these are indicated for pain.*/
/**************************************************************************************************************************************************/

proc sql;
create table hcs_bup_17 as /*to be used for measures that require look-back*/
select unique * 
from all_records_step_f a, bup b
where a.ndc11_char = b.ndc_char and 
		a.age_at_fill ge 17;
quit;

proc sql;
create table hcs_bup_18 as /*to be used for measures that do not require look-back*/
select unique * 
from all_records_step_f a, bup b
where a.ndc11_char = b.ndc_char and 
		a.age_at_fill ge 18;
quit;


/**************************************************************************************************************************************************/
/*Step N. From the table created in step F, use the  HCS Approved dataset with appended MME data to select all filled prescriptions for opioids. */
/*Exclude the following buprenorphine formulations: extended release subcutaneous, implant, and tablet. Exclude buprenorphine/naloxone film. */
/*Exclude solution formulations of codeine.*/
/**************************************************************************************************************************************************/

proc sql;
create table hcs_opioid_17 as
select unique *
from all_records_step_f a, opioid b
where 	a.ndc11_char = b.ndc_char and 
		a.age_at_fill ge 17;
quit;

proc sql;
create table hcs_opioid_18 as
select unique *
from all_records_step_f a, opioid b
where 	a.ndc11_char = b.ndc_char and 
		a.age_at_fill ge 18;
quit;

/**************************************************************************************************************************************************/
/*Step O.From the table created in step F, use the  HCS Approved dataset to select all filled prescriptions for benzodiazepines.*/
/**************************************************************************************************************************************************/
proc sql;
create table hcs_benzo as
select unique *
from all_records_step_f a, benzo b
where a.ndc11_char = b.ndc_char;
quit;


proc datasets NOLIST;
	delete step_g;
quit;
/************************************************************************************************************************/
/*calculate periods of continuous treatment for opioids and buprenorphine*/
/************************************************************************************************************************/

%macro continuous(dset);


proc sql;
create table &dset._step01 as
select unique 	patient_id length = 100, 
				&start_date as date_filled format date9.,
				0 as quantity_dispensed,
				0 as days_dispensed,
				1 as filler_record
from &dset
union all
select unique 	patient_id length = 100,
				&end_date as date_filled format date9.,
				0 as quantity_dispensed,
				0 as days_dispensed,
				1 as filler_record
from &dset
;
quit;

data &dset._step02; set &dset. &dset._step01; run;

proc sort data=&dset._step02; by patient_id date_filled descending days_dispensed; run;

data &dset._step03; set &dset._step02; by patient_id date_filled descending days_dispensed;
retain patient_obs_incl_overlap;
if first.patient_id then patient_obs_incl_overlap = 1;
else patient_obs_incl_overlap = patient_obs_incl_overlap + 1;

if filler_record = 1 then date_run_out = date_filled + 0;

run;


/*Compare the fill dates and run-out dates of each prescription. */
/*If one prescription completely overlaps a prescription with a shorter duration and an earlier run-out */
/*date (fill date B = fill date A and run-out date B < run-out date A) then remove the prescription with the shorter */
/*duration.  */


proc sql;
create table &dset._step04_temp as
select 	a.patient_id length = 100,
		a.patient_obs_incl_overlap,
		a.date_filled, 
		a.days_dispensed, 
		a.date_run_out,
		pre.date_run_out as pre_date_run_out,
		1 as overlapped
from &dset._step03 a, &dset._step03 pre
where  a.patient_id = pre.patient_id and
		((a.patient_obs_incl_overlap-1) = pre.patient_obs_incl_overlap or
		 (a.patient_obs_incl_overlap-2) = pre.patient_obs_incl_overlap or
		 (a.patient_obs_incl_overlap-3) = pre.patient_obs_incl_overlap or
		 (a.patient_obs_incl_overlap-4) = pre.patient_obs_incl_overlap or
		 (a.patient_obs_incl_overlap-5) = pre.patient_obs_incl_overlap or
		 (a.patient_obs_incl_overlap-6) = pre.patient_obs_incl_overlap or
		 (a.patient_obs_incl_overlap-7) = pre.patient_obs_incl_overlap or
		 (a.patient_obs_incl_overlap-8) = pre.patient_obs_incl_overlap or
		 (a.patient_obs_incl_overlap-9) = pre.patient_obs_incl_overlap or
		 (a.patient_obs_incl_overlap-10) = pre.patient_obs_incl_overlap ) and 
	  a.filler_record ne 1 and
	  a.date_run_out < pre.date_run_out
order by a.patient_id, a.patient_obs_incl_overlap;
quit;



proc sql;
create table &dset._step04 as
select unique patient_id, patient_obs_incl_overlap
from &dset._step04_temp
where patient_id ne '';
quit;



data &dset._step05; merge &dset._step03(in=a) &dset._step04(in=b); by patient_id patient_obs_incl_overlap; 
if  b then delete; /*delete overlapped records to calculate treatment gaps*/
run;


data &dset._step06; set &dset._step05; by patient_id patient_obs_incl_overlap; 
retain patient_obs_excl_overlap;

if first.patient_id then patient_obs_excl_overlap = 1;
else patient_obs_excl_overlap = patient_obs_excl_overlap + 1;
run;

proc sql;
create table &dset._step07 as
select  a.patient_id,
		a.patient_obs_excl_overlap,
		a.date_filled, 
		a.days_dispensed, 
		a.date_run_out,
		a.filler_record,
		a.age_at_fill,	
		(b.date_filled - a.date_run_out - 1) as gap_after
from &dset._step06 a, &dset._step06 b
where a.patient_id = b.patient_id and
	  b.patient_obs_excl_overlap = (a.patient_obs_excl_overlap + 1)
order by a.patient_id, a.patient_obs_excl_overlap;
quit;

proc sql;
create table &dset._step08 as
select  a.patient_id,
		a.patient_obs_excl_overlap,
		b.gap_after as gap_prior
from &dset._step07 a, &dset._step07 b
where a.patient_id = b.patient_id and
	  b.patient_obs_excl_overlap = (a.patient_obs_excl_overlap - 1)
order by a.patient_id, a.patient_obs_excl_overlap;
quit;

data &dset._step09; merge &dset._step07 &dset._step08; by patient_id patient_obs_excl_overlap;
if filler_record = 1 then delete;
drop filler_record;
run;

data &dset._step10; set &dset._step09; by patient_id patient_obs_excl_overlap;
retain contin_period;
if first.patient_id then contin_period = 1;
if not first.patient_id and gap_prior ge 8 then contin_period = contin_period+1;
run;

proc sql;
create table &dset._step11 as
select unique 	patient_id,
				contin_period,
				min(patient_obs_excl_overlap) as min_patient_obs_excl_overlap,
				min(date_filled) as min_date_filled format date9.,
				max(date_run_out) as max_date_run_out format date9.,
				(max(date_run_out) - min(date_filled) + 1) as duration
from &dset._step10
group by patient_id, contin_period;
quit;

proc sql;
create table &dset._step12 as 
select a.*, 
	   b.gap_prior
from &dset._step11 a, &dset._step10 b, &dset._step06 c
where a.patient_id = b.patient_id and
	  a.patient_id = c.patient_id and
	  a.min_patient_obs_excl_overlap = b.patient_obs_excl_overlap and
	  a.min_patient_obs_excl_overlap = c.patient_obs_excl_overlap;
quit;

*STEP ADDED BY NYS FOR AGE AND GENDER STRATIFICATION, AND, STATE COUNTS;

proc sort data=&dset._step12;
by patient_id;
run;

proc sql;
create table &dset._lastfill_a  as
select  patient_id length = 100,date_filled as last_fill ,year(date_filled) as year_filled 
from &dset 
order by patient_id,date_filled desc;
quit;

proc sort data=&dset._lastfill_a out=&dset._lastfill  nodupkey;
by patient_id year_filled;
run;


%mend continuous;

%continuous(hcs_bup_17);
%continuous(hcs_bup_18);
%continuous(hcs_opioid_17);
%continuous(hcs_opioid_18);

/*******************************************************************************************************/
/******************************************** Outcome 2.13 *********************************************/
/*********************************INCIDENT HIGH-RISK OPIOID PRESCRIBING*********************************/
/*******************************************************************************************************/
/*******************************************************************************************************/


/**********************************************************************************/
/*A. Risk of continued opioid use (new opioid episode lasting at least 31 days)   */
/**********************************************************************************/

data outcome_2_13_a_step00; 
set hcs_opioid_18_step12;
year = year(min_date_filled);
quarter = qtr(min_date_filled);
month = month(min_date_filled);
where gap_prior ge 45;
run;
data outcome_2_13_a_step01;
set outcome_2_13_a_step00;
where duration ge 31;
run;

/********************************/
/********************************/
/********************************/
data outcome_2_13_a_step01; 
set hcs_opioid_18_step12;
year = year(min_date_filled);
quarter = qtr(min_date_filled);
month = month(min_date_filled);
where duration ge 31 and gap_prior ge 45;
run;
proc sql;
create table outcome_2_13_a_step02 as
select unique	patient_id, 
				year, 
				quarter,
				month
from outcome_2_13_a_step01;
quit;

proc sql;
create table outcome_2_13_a_step03 as 
select 	a.patient_id,
		a.year,
		a.month,
		b.community
from outcome_2_13_a_step02 a, step_j b
where a.patient_id = b.patient_id and
	  a.year = b.year and
	  a.month = b.month;
quit;

proc sql;
create table outcome_2_13_a_step04 as 
select 	a.patient_id,
		a.year,
		a.quarter,
		b.community
from outcome_2_13_a_step02 a, step_k b
where a.patient_id = b.patient_id and
	  a.year = b.year and
	  a.quarter = b.quarter;
quit;

proc sql;
create table outcome_2_13_a_step05 as 
select 	a.patient_id,
		a.year,
        b.community
from outcome_2_13_a_step02 a, step_l b
where a.patient_id = b.patient_id and
	  a.year = b.year;
quit;

/*************************************************************************************************/
/*************************************************************************************************/
/*************************************************************************************************/
/**/
/*NYS ADDITION AND EDIT:STEP 6 TO STARIFY FOR AGE AND GENDER FOR STATE AND COMMUNITY COUNTS;*/
/**/
/*************************************************************************************************/
/*************************************************************************************************/
/*************************************************************************************************/

proc sql;
create table outcome_2_13_a_step06a as
SELECT a.* ,b.*
FROM outcome_2_13_a_step05 a
LEFT JOIN hcs_opioid_18_lastfill b
ON a.patient_id = b.patient_id and a.year=b.year_filled ;
quit;
proc sql;
create table outcome_2_13_a_step06b as 
select 	a.patient_id, a.year,	a.last_fill,b.gender,b.dob,a.community,
int(yrdif(b.dob, a.last_fill,'ACTUAL')) as age_at_lastfill
from outcome_2_13_a_step06a a left join pmp_gender_dob b
on a.patient_id = b.patient_id 	  ;
quit;
data outcome_2_13_a_step06;
set outcome_2_13_a_step06b;
If gender not in ('1' '2') then gender  ='0';

if age_at_lastfill eq . then do;
age_at_lastfill=int(yrdif(dob, mdy(12,31,year),'ACTUAL'));
end;

IF age_at_lastfill EQ . THEN age_cat=0;
ELSE if 18<=age_at_lastfill<=34 then age_cat=1;
else if 35<=age_at_lastfill<=54 then age_cat=2;
else if age_at_lastfill GE 55 then age_cat=3;
run;
*formats heal_age heal_gender;

%macro count_months(measure, dset);
proc sql;
create table temp_&measure._counts_m as
select unique 	a.community, 
				a.year, 
				a.month,
				b.complete,
				count(unique a.patient_id) as patient_count	
from &dset a, months b
where a.year = b.year and
	  a.month = b.month	
group by a.community, a.year, a.month;
quit;

data outcome_&measure._counts_m1; 
merge all_possible_m (in=x) temp_&measure._counts_m (in=y); by community year month;
if x;
if not y then patient_count = 0;
run;

data outcome_&measure._counts_m2;
 set outcome_&measure._counts_m1;
if community in ('Brookhaven Township' 'Rest of Suffolk') then community='Suffolk';
if community in ('Buffalo' 'Rest of Erie') then community='Erie';
if community in ('Rochester' 'Rest of Monroe') then community='Monroe';
where  community in ('Brookhaven Township' 'Rest of Suffolk' 'Buffalo' 'Rest of Erie' 'Rochester' 'Rest of Monroe');
run;

proc sql noprint;
create table outcome_&measure._counts_m3 as 
select unique community, year, month,complete, sum(patient_count) as patient_count
from outcome_&measure._counts_m2 
group by community, year, month;
quit;

data outcome_&measure._counts_m;
set outcome_&measure._counts_m1 outcome_&measure._counts_m3;
run;

%mend count_months;

%macro count_qtrs(measure, dset);
proc sql;
create table temp_&measure._counts_q as
select unique 	a.community, 
				a.year, 
				a.quarter,
				b.complete,
				count(unique a.patient_id) as patient_count	
from &dset a, quarters b
where a.year = b.year and
	  a.quarter = b.quarter	
group by a.community, a.year, a.quarter;
quit;


data outcome_&measure._counts_q1; 
merge all_possible_q (in=x) temp_&measure._counts_q (in=y); by community year quarter;
if x;
if not y then patient_count = 0;
run;

data outcome_&measure._counts_q2;
set outcome_&measure._counts_q1;
if community in ('Brookhaven Township' 'Rest of Suffolk') then community='Suffolk';
if community in ('Buffalo' 'Rest of Erie') then community='Erie';
if community in ('Rochester' 'Rest of Monroe') then community='Monroe';
where  community in ('Brookhaven Township' 'Rest of Suffolk' 'Buffalo' 'Rest of Erie' 'Rochester' 'Rest of Monroe');
run;

proc sql noprint;
create table outcome_&measure._counts_q3 as 
select unique community, year, quarter,complete, sum(patient_count) as patient_count
from outcome_&measure._counts_q2 
group by community, year, quarter;
quit;

data outcome_&measure._counts_q;
set outcome_&measure._counts_q1 outcome_&measure._counts_q3;
run;

%mend count_qtrs;
%macro count_years(measure, dset);
proc sql;
create table temp_&measure._counts_y as
select unique 	a.community, 
				a.year, 
				b.complete,
				count(unique a.patient_id) as patient_count	
from &dset a, years b
where a.year = b.year
group by a.community, a.year;
quit;


data outcome_&measure._counts_y1; 
merge all_possible_y (in=x) temp_&measure._counts_y (in=y); by community year;
if x;
if not y then patient_count = 0;
run;

data outcome_&measure._counts_y2; 
set outcome_&measure._counts_y1; 
if community in ('Brookhaven Township' 'Rest of Suffolk') then community='Suffolk';
if community in ('Buffalo' 'Rest of Erie') then community='Erie';
if community in ('Rochester' 'Rest of Monroe') then community='Monroe';
where  community in ('Brookhaven Township' 'Rest of Suffolk' 'Buffalo' 'Rest of Erie' 'Rochester' 'Rest of Monroe');
run;

proc sql noprint;
create table outcome_&measure._counts_y3 as 
select unique community, year,complete,  sum(patient_count) as patient_count
from outcome_&measure._counts_y2 
group by community, year;
quit;

data outcome_&measure._counts_y;
set outcome_&measure._counts_y1 outcome_&measure._counts_y3;
run;

%mend count_years;
%macro community_age(measure, dset);
proc sql;
create table t_&measure._cage as
select unique 	a.community, 
				a.year, a.age_cat,
				b.complete,
				count(unique a.patient_id) as patient_count	
from &dset a, years b
where a.year = b.year
group by a.community, a.year,a.age_cat;
quit;


data outcome_&measure._cage1; 
merge all_possible_y_age (in=x) t_&measure._cage (in=y); by community year age_cat;
if x;
if not y then patient_count = 0;
run;

data outcome_&measure._cage2; 
set outcome_&measure._cage1; 
if community in ('Brookhaven Township' 'Rest of Suffolk') then community='Suffolk';
if community in ('Buffalo' 'Rest of Erie') then community='Erie';
if community in ('Rochester' 'Rest of Monroe') then community='Monroe';
where  community in ('Brookhaven Township' 'Rest of Suffolk' 'Buffalo' 'Rest of Erie' 'Rochester' 'Rest of Monroe');
run;

proc sql noprint;
create table outcome_&measure._cage3 as 
select unique community, year,complete,age_cat, sum(patient_count) as patient_count
from outcome_&measure._cage2
group by community, year,age_cat;
quit;

data outcome_&measure._cage;
set outcome_&measure._cage1 outcome_&measure._cage3;
run;

%mend community_age;
%macro community_gender(measure, dset);
proc sql;
create table t_&measure._cgender as
select unique 	a.community, 
				a.year, a.gender,
				b.complete,
				count(unique a.patient_id) as patient_count	
from &dset a, years b
where a.year = b.year
group by a.community, a.year,a.gender;
quit;


data outcome_&measure._cgender1; 
merge all_possible_y_gender (in=x) t_&measure._cgender (in=y); by community year gender;
if x;
if not y then patient_count = 0;
run;

data outcome_&measure._cgender2; 
set outcome_&measure._cgender1; 
if community in ('Brookhaven Township' 'Rest of Suffolk') then community='Suffolk';
if community in ('Buffalo' 'Rest of Erie') then community='Erie';
if community in ('Rochester' 'Rest of Monroe') then community='Monroe';
where  community in ('Brookhaven Township' 'Rest of Suffolk' 'Buffalo' 'Rest of Erie' 'Rochester' 'Rest of Monroe');
run;

proc sql noprint;
create table outcome_&measure._cgender3 as 
select unique community, year,complete,gender, sum(patient_count) as patient_count
from outcome_&measure._cgender2
group by community, year,gender;
quit;

data outcome_&measure._cgender;
set outcome_&measure._cgender1  outcome_&measure._cgender3;
run;


%mend community_gender;

%macro count_state(measure, dset);
proc sql;
create table t_&measure._state as
select  unique	"New York State" as community length=100, 
				a.year, 
				b.complete,
				count(unique a.patient_id) as patient_count	
from &dset a, years b
where a.year = b.year
group by  a.year
order by community,a.year;
quit;


data outcome_&measure._state; 
merge all_possible_y_state (in=x) t_&measure._state (in=y); by community year;
if x;
if not y then patient_count = 0;
run;

%mend count_state;
%macro state_age(measure, dset);
proc sql;
create table t_&measure._sage as
select unique 	"New York State" as community length=100, 
				a.year,a.age_cat ,
				b.complete,
				count(unique a.patient_id) as patient_count	
from &dset a, years b
where a.year = b.year
group by  a.year,a.age_cat
order by community,a.year,a.age_cat ;


data outcome_&measure._sage; 
merge all_possible_y_age_st (in=x) t_&measure._sage (in=y); by community year age_cat;
if x;
if not y then patient_count = 0;
run;

%mend state_age;

%macro state_gender(measure, dset);
proc sql;
create table t_&measure._sgender as
select unique 	"New York State" as community length=100, 
				a.year,a.gender,
				b.complete,
				count(unique a.patient_id) as patient_count	
from &dset a, years b
where a.year = b.year
group by  a.year,a.gender
order by a.year,gender;
quit;


data outcome_&measure._sgender; 
merge all_possible_y_gender_st (in=x) t_&measure._sgender (in=y); by community year gender;
if x;
if not y then patient_count = 0;
run;

%mend state_gender;
%count_months(2_13_a, outcome_2_13_a_step03);
%count_qtrs(2_13_a, outcome_2_13_a_step04);
%count_years(2_13_a, outcome_2_13_a_step06);
%count_state(2_13_a, outcome_2_13_a_step06);
%state_age(2_13_a, outcome_2_13_a_step06);
%state_gender(2_13_a, outcome_2_13_a_step06);
%community_gender(2_13_a, outcome_2_13_a_step06);
%community_age(2_13_a, outcome_2_13_a_step06);
/**********************************************************************************/
/*B. Initiating opioid treatment with Extended-release or Long-acting opioid      */
/**********************************************************************************/
/***************************************************************************************************************/
/*Correction 20200428. Was previously using outcome_2_13_a_step01, which is limited to episodes lasting 31 days*/
/********************************Now using the new outcome_2_13_a_step00****************************************/
/***************************************************************************************************************/
/*possibly creating multiple records if two opioid prescriptions filled on one day but select unique in next step*/
proc sql;
create table outcome_2_13_b_step01
as select a.*, b.long_act  
from outcome_2_13_a_step00 a,
	 hcs_opioid_18 b
where 	a.patient_id = b.patient_id and
		a.min_date_filled = b.date_filled and
		b.long_act = 1;
quit;

proc sql;
create table outcome_2_13_b_step02
as select unique 	patient_id,
					year,
					quarter,
					month
from outcome_2_13_b_step01;
quit;
proc sql;
create table outcome_2_13_b_step03 as 
select unique 	a.patient_id,
				a.year,
				a.month,
				b.community
from outcome_2_13_b_step02 a, step_j b
where a.patient_id = b.patient_id and
	  a.year = b.year and
	  a.month = b.month;
quit;

proc sql;
create table outcome_2_13_b_step04 as 
select unique 	a.patient_id,
				a.year,
				a.quarter,
				b.community
from outcome_2_13_b_step02 a, step_k b
where a.patient_id = b.patient_id and
	  a.year = b.year and
	  a.quarter = b.quarter;
quit;

proc sql;
create table outcome_2_13_b_step05 as 
select unique 	a.patient_id,
				a.year,
				b.community
from outcome_2_13_b_step02 a, step_l b
where a.patient_id = b.patient_id and
	  a.year = b.year;
quit;
/*************************************************************************************************/
/*************************************************************************************************/
/*************************************************************************************************/
/**/
/*NYS ADDITION AND EDIT:STEP 6 TO STARIFY FOR AGE AND GENDER FOR STATE AND COMMUNITY COUNTS;*/
/**/
/*************************************************************************************************/
/*************************************************************************************************/
/*************************************************************************************************/
proc sql;
create table outcome_2_13_b_step06a as
SELECT a.* ,b.*
FROM outcome_2_13_b_step05 a
LEFT JOIN hcs_opioid_18_lastfill b
ON a.patient_id = b.patient_id and a.year=b.year_filled ;
quit;
proc sql;
create table outcome_2_13_b_step06b as 
select 	a.patient_id, a.year,	a.last_fill,b.gender,b.dob,a.community,
int(yrdif(b.dob, a.last_fill,'ACTUAL')) as age_at_lastfill
from outcome_2_13_b_step06a a left join pmp_gender_dob b
on a.patient_id = b.patient_id 	  ;
quit;
data outcome_2_13_b_step06;
set outcome_2_13_b_step06b;
If gender not in ('1' '2') then gender  ='0';

if age_at_lastfill eq . then do;
age_at_lastfill=int(yrdif(dob, mdy(12,31,year),'ACTUAL'));
end;

IF age_at_lastfill EQ . THEN age_cat=0;
else if 18<=age_at_lastfill<=34 then age_cat=1;
else if 35<=age_at_lastfill<=54 then age_cat=2;
else if age_at_lastfill ge 55 then age_cat=3;
run;
%count_months(2_13_b, outcome_2_13_b_step03);
%count_qtrs(2_13_b, outcome_2_13_b_step04);
%count_years(2_13_b, outcome_2_13_b_step06);
%count_state(2_13_b, outcome_2_13_b_step06);
%state_age(2_13_b, outcome_2_13_b_step06);
%state_gender(2_13_b, outcome_2_13_b_step06);
%community_gender(2_13_b, outcome_2_13_b_step06);
%community_age(2_13_b, outcome_2_13_b_step06);

/**********************************************************************************/
/*C. Incident High dosage (average > 90 mg morphine per day)                   */
/**********************************************************************************/

data outcome_2_13_c_step01; 
set hcs_opioid_17;
where mme_conversion_factor ne .;
keep patient_id date_filled days_dispensed strength_per_unit quantity_dispensed mme_conversion_factor date_run_out;
run;

data outcome_2_13_c_step02;
set outcome_2_13_c_step01;
mme_per_day = strength_per_unit*mme_conversion_factor*(quantity_dispensed/days_dispensed);
run;

/*CREATING A NULL ROW*/
proc sql;
create table outcome_2_13_c_step03 as
select unique 	"xxxxxxxxxxxxxxx" as patient_id length= 100  ,
				mdy(01,01,2000) as date format date9.,
				2000 as year,
				1 as month,
				sum(mme_per_day) as mme
from outcome_2_13_c_step02
where date_filled le mdy(01,01,2000) le date_run_out;
quit;

/*********************************************************************************************************************************/
/*********************************************************************************************************************************/
/*********************************************************************************************************************************/
/*********************************************************************************************************************************/
/****************THIS IS THE STEP THAT WAS DISCUSSED ON THE MARCH 12, 2020 WEEKLY DATA CAPTURE LEADERSHIP WG CALL*****************/
/*********************************************************************************************************************************/
/*********************************************************************************************************************************/
/*********************************************************************************************************************************/
/*********************************************************************************************************************************/

%macro mme_per_day(date);

proc sql noprint;
insert into outcome_2_13_c_step03
select unique 	patient_id,
				&date as date format date9.,
				year(&date) as year,
				month(&date) as month,
				sum(mme_per_day) as mme
from outcome_2_13_c_step02
where date_filled le &date le date_run_out
group by patient_id
;
quit;

%mend mme_per_day;
/*NEW 20200501 to suppress notes in the log*/
options nomprint nosymbolgen nonotes nosource;
/*******************************************/
data _null_; 
set date_range;
call execute('%mme_per_day('||date||')');
run;

options mprint symbolgen notes source;
proc sql;
create table outcome_2_13_c_step04 as
select unique 	patient_id,
				year,
				month,
				sum(mme) as mme_month_total
from outcome_2_13_c_step03
where year ne 2000
group by patient_id, year, month;
quit;
proc sql;
create table outcome_2_13_c_step05 as 
select unique 	a.patient_id, 
				b.year, 
				b.month,
				b.days
from outcome_2_13_c_step04 a, months b
where b.complete = 1
order by 	a.patient_id,
			b.year,
			b.month;
quit;
data outcome_2_13_c_step06; merge outcome_2_13_c_step05 outcome_2_13_c_step04 (in=b); by patient_id year month; 
if not b then mme_month_total = 0;
run;
proc sort data=outcome_2_13_c_step06; by patient_id year month; run;
data outcome_2_13_c_step07; set outcome_2_13_c_step06; by patient_id year month;
retain obs;
if first.patient_id then obs = 1;
else obs = obs+1;
run;

proc sql;
create table outcome_2_13_c_step08 as
select 	a.*, 
		sum(a.mme_month_total, b.mme_month_total, c.mme_month_total) as moving_sum format 9.2,
		sum(a.days, b.days, c.days) as days_in_moving_quarter
from outcome_2_13_c_step07 a, outcome_2_13_c_step07 b, outcome_2_13_c_step07 c
where 	a.patient_id = b.patient_id and
		b.patient_id = c.patient_id and 
		b.obs = (a.obs - 1) and
		c.obs = (b.obs - 1);
quit;

data outcome_2_13_c_step09; set outcome_2_13_c_step08;
	mean_daily_dosage = moving_sum/days_in_moving_quarter;
	if mean_daily_dosage ge 90 then interim_flag_1 = 1;
	if 0 le mean_daily_dosage lt 90 then interim_flag_1 = 0;
format mean_daily_dosage 8.2;
run;


proc sql;
create table outcome_2_13_c_step10 as 
select a.*, b.interim_flag_1 as interim_flag_2
from outcome_2_13_c_step09 a, outcome_2_13_c_step09 b
where a.patient_id = b.patient_id and 
	 b.obs = (a.obs-3);
quit;

%macro compare_flags();
if interim_flag_1 = . or interim_flag_2 = . then measure_flag = .;
if interim_flag_1 in (0,1) and interim_flag_2 = 1 then measure_flag = 0;
if interim_flag_1 = 1 and interim_flag_2 = 0 then measure_flag = 1;
if interim_flag_1 = 0 and interim_flag_2 = 0 then measure_flag = 0;
%mend compare_flags;

data outcome_2_13_c_step11; set outcome_2_13_c_step10;
%compare_flags();
run;


proc sql;
create table outcome_2_13_c_step12 as
select 	a.*,
		b.year_18yo, 
		b.month_dob
from outcome_2_13_c_step11 a, pmp_dobs b 
where 	a.patient_id = b.patient_id and
		(a.year ge b.year_18yo or (a.year eq b.year_18yo and a.month ge b.month_dob));
quit;


proc sql; 
create table outcome_2_13_c_step13 as 
select unique patient_id, year, month
from outcome_2_13_c_step12
where measure_flag = 1;
quit;

/*modified in version 13*/
/*From the table created in C30, flag calendar */
/*quarters that include one or more months where 2.13C flag = 1.*/

data outcome_2_13_c_step14; 
set outcome_2_13_c_step13;
if month in (1,2,3) then quarter = 1;
if month in (4,5,6) then quarter = 2;
if month in (7,8,9) then quarter = 3;
if month in (10,11,12) then quarter = 4;
run;

proc sql;
create table outcome_2_13_c_step15 as
select unique 	patient_id, 
				year, 
				quarter
from outcome_2_13_c_step14
where quarter ne .;
quit;

proc sql;
create table outcome_2_13_c_step16 as
select unique 	patient_id, 
				year
from outcome_2_13_c_step15;
quit;


proc sql;
create table outcome_2_13_c_step17 as 
select 	a.patient_id,
		a.year,
		a.month,
		b.community
from outcome_2_13_c_step13 a, step_j b
where a.patient_id = b.patient_id and
	  a.year = b.year and
	  a.month = b.month;
quit;

proc sql;
create table outcome_2_13_c_step18 as 
select 	a.patient_id,
		a.year,
		a.quarter,
		b.community
from outcome_2_13_c_step15 a, step_k b
where a.patient_id = b.patient_id and
	  a.year = b.year and
	  a.quarter = b.quarter;
quit;

proc sql;
create table outcome_2_13_c_step19 as 
select 	a.patient_id,
		a.year,
		b.community
from outcome_2_13_c_step16 a, step_l b
where a.patient_id = b.patient_id and
	  a.year = b.year;
quit;

/*************************************************************************************************/
/*************************************************************************************************/
/*************************************************************************************************/
/**/
/*NYS ADDITION AND EDIT:STEP 6 TO STARIFY FOR AGE AND GENDER FOR STATE AND COMMUNITY COUNTS;*/
/**/
/*************************************************************************************************/
/*************************************************************************************************/
/*************************************************************************************************/
proc sql;
create table outcome_2_13_c_step20a as
SELECT a.* ,b.*
FROM outcome_2_13_c_step19 a
LEFT JOIN hcs_opioid_17_lastfill b
ON a.patient_id = b.patient_id and a.year=b.year_filled ;
quit;
proc sql;
create table outcome_2_13_c_step20b as 
select 	a.patient_id, a.year,	a.last_fill,b.gender,b.dob,a.community,
int(yrdif(b.dob, a.last_fill,'ACTUAL')) as age_at_lastfill
from outcome_2_13_c_step20a a left join pmp_gender_dob b
on a.patient_id = b.patient_id 	  ;
quit;
data outcome_2_13_c_step20;
set outcome_2_13_c_step20b;
If gender not in ('1' '2')  then gender  ='0';

if age_at_lastfill eq . then do;
age_at_lastfill=int(yrdif(dob, mdy(12,31,year),'ACTUAL'));
end;

if age_at_lastfill ne . and age_at_lastfill le 17 then delete;
else IF age_at_lastfill EQ . THEN age_cat=0;
else if 18<=age_at_lastfill<=34 then age_cat=1;
else if 35<=age_at_lastfill<=54 then age_cat=2;
else if age_at_lastfill ge 55 then age_cat=3;
format dob mmddyy10.;
run;
%count_months(2_13_c, outcome_2_13_c_step17);
%count_qtrs(2_13_c, outcome_2_13_c_step18);
%count_years(2_13_c, outcome_2_13_c_step20);
%count_state(2_13_c, outcome_2_13_c_step20);
%state_age(2_13_c, outcome_2_13_c_step20);
%state_gender(2_13_c, outcome_2_13_c_step20);
%community_gender(2_13_c, outcome_2_13_c_step20);
%community_age(2_13_c, outcome_2_13_c_step20);

/**********************************************************************************/
/*D. Incident Overlapping opioid and benzodiazepine for at least 31 days       */
/**********************************************************************************/
data outcome_2_13_d_step01; 
set hcs_benzo;
keep patient_id date_filled days_dispensed quantity_dispensed date_run_out;
run;
/*CREATING A NULL ROW*/
proc sql;
create table outcome_2_13_d_step02 as
select unique 	"xxxxxxxxx" as patient_id length=100 , 
				mdy(01,01,2000) as date format date9.,
				1 as benzo
from outcome_2_13_d_step01
where date_filled le mdy(01,01,2000) le date_run_out;
quit;
%macro benzo_per_day(date);

proc sql noprint;
reset noprint;
insert into outcome_2_13_d_step02
select unique 	patient_id, 
				&date as date format date9.,
				1 as benzo
from outcome_2_13_d_step01
where date_filled le &date le date_run_out;
quit;

%mend benzo_per_day;

/*NEW 20200501 to suppress notes in the log*/
options nomprint nosymbolgen nonotes nosource ;
/*******************************************/
data _null_; 
set date_range;
call execute('%benzo_per_day('||date||')');
run;
options mprint symbolgen notes source;


proc sort data=outcome_2_13_d_step02; by patient_id date; run;
proc sort data=outcome_2_13_c_step03; by patient_id date; run;


data outcome_2_13_d_step03;
merge outcome_2_13_d_step02 (in=a) outcome_2_13_c_step03(in=b); by patient_id date; 
if a and b;
run; 


proc sql;
create table outcome_2_13_d_step04 as
select unique 	patient_id,
				year,
				month,
				count(patient_id) as days_of_overlap
from outcome_2_13_d_step03
where year ne 2000
group by patient_id, year, month;
quit;

proc sql;
create table outcome_2_13_d_step05 as 
select unique 	a.patient_id, 
				b.year, 
				b.month
from outcome_2_13_d_step04 a, months b
where b.complete = 1
order by 	a.patient_id,
			b.year,
			b.month;
quit;

data outcome_2_13_d_step06; merge outcome_2_13_d_step05 outcome_2_13_d_step04 (in=b); by patient_id year month; 
if not b then days_of_overlap = 0;
run;

data outcome_2_13_d_step07; set outcome_2_13_d_step06; by patient_id year month;
retain obs;
if first.patient_id then obs = 1;
else obs = obs+1;
run;

proc sql;
create table outcome_2_13_d_step08 as
select 	a.*, 
		sum(a.days_of_overlap, b.days_of_overlap, c.days_of_overlap) as moving_sum
from outcome_2_13_d_step07 a, outcome_2_13_d_step07 b, outcome_2_13_d_step07 c
where 	a.patient_id = b.patient_id and
		b.patient_id = c.patient_id and 
		b.obs = (a.obs - 1) and
		c.obs = (b.obs - 1);
quit;

data outcome_2_13_d_step09; set outcome_2_13_d_step08;
	if moving_sum ge 31 then interim_flag_1 = 1;
	if 0 le moving_sum lt 31 then interim_flag_1 = 0;
run;

proc sql;
create table outcome_2_13_d_step10 as 
select a.*, b.interim_flag_1 as interim_flag_2
from outcome_2_13_d_step09 a, outcome_2_13_d_step09 b
where a.patient_id = b.patient_id and 
	 b.obs = (a.obs-3);
quit;

data outcome_2_13_d_step11; set outcome_2_13_d_step10;
%compare_flags();
run;


proc sql;
create table outcome_2_13_d_step12 as
select 	a.*,
		b.year_18yo, 
		b.month_dob
from outcome_2_13_d_step11 a, pmp_dobs b 
where 	a.patient_id = b.patient_id and
		(a.year ge b.year_18yo or (a.year eq b.year_18yo and a.month ge b.month_dob));
quit;

proc sql; 
create table outcome_2_13_d_step13 as 
select unique patient_id, year, month
from outcome_2_13_d_step12
where measure_flag = 1;
quit;


/*new in version 13*/
/*From the table created in D43, flag calendar quarters */
/*that include one or more months*/
/*where 2.13D flag = 1.*/

data outcome_2_13_d_step14;
set outcome_2_13_d_step13;
if month in (1,2,3) then quarter = 1;
if month in (4,5,6) then quarter = 2;
if month in (7,8,9) then quarter = 3;
if month in (10,11,12) then quarter = 4;
run;

proc sql;
create table outcome_2_13_d_step15 as
select unique 	patient_id, 
				year, 
				quarter
from outcome_2_13_d_step14
where quarter ne .;
quit;

proc sql;
create table outcome_2_13_d_step16 as
select unique 	patient_id, 
				year
from outcome_2_13_d_step15;
quit;


proc sql;
create table outcome_2_13_d_step17 as 
select unique 	a.patient_id,
				a.year,
				a.month,
				b.community
from outcome_2_13_d_step13 a, step_j b
where a.patient_id = b.patient_id and
	  a.year = b.year and
	  a.month = b.month;
quit;

proc sql;
create table outcome_2_13_d_step18 as 
select unique  	a.patient_id,
				a.year,
				a.quarter,
				b.community
from outcome_2_13_d_step15 a, step_k b
where a.patient_id = b.patient_id and
	  a.year = b.year and
	  a.quarter = b.quarter;
quit;

proc sql;
create table outcome_2_13_d_step19 as 
select unique  	a.patient_id,
				a.year,
				b.community
from outcome_2_13_d_step16 a, step_l b
where a.patient_id = b.patient_id and
	  a.year = b.year;
quit;

/*************************************************************************************************/
/*************************************************************************************************/
/*************************************************************************************************/
/**/
/*NYS ADDITION AND EDIT:STEP 6 TO STARIFY FOR AGE AND GENDER FOR STATE AND COMMUNITY COUNTS;*/
/**/
/*************************************************************************************************/
/*************************************************************************************************/
/*************************************************************************************************/
data opioid_17_benzo;
set hcs_opioid_17 hcs_benzo ;
keep patient_id date_filled year_filled;
run;
proc sort data=opioid_17_benzo ;
by patient_id year_filled descending date_filled;
run;
proc sort data=opioid_17_benzo out=opioid_17_benzo_lastfill nodupkey;
by patient_id year_filled ;
run;
proc sql;
create table outcome_2_13_d_step20a as
SELECT a.* ,b.year_filled, b.date_filled as last_fill
FROM outcome_2_13_d_step19 a
LEFT JOIN opioid_17_benzo_lastfill b
ON a.patient_id = b.patient_id and a.year=b.year_filled ;
quit;
proc sql;
create table outcome_2_13_d_step20b as 
select 	a.patient_id, a.year,	a.last_fill,b.gender,b.dob,a.community,
int(yrdif(b.dob, a.last_fill,'ACTUAL')) as age_at_lastfill
from outcome_2_13_d_step20a a left join pmp_gender_dob b
on a.patient_id = b.patient_id 	  ;
quit;
data outcome_2_13_d_step20;
set outcome_2_13_d_step20b;
If gender not in ('1' '2') then gender  ='0';

if age_at_lastfill eq . then do;
age_at_lastfill=int(yrdif(dob, mdy(12,31,year),'ACTUAL'));
end;

if age_at_lastfill ne . and age_at_lastfill le 17 then delete;
else IF age_at_lastfill EQ . THEN age_cat=0;
else if 18<=age_at_lastfill<=34 then age_cat=1;
else if 35<=age_at_lastfill<=54 then age_cat=2;
else if age_at_lastfill ge 55 then age_cat=3;
format dob mmddyy10.;
run;
%count_months(2_13_d, outcome_2_13_d_step17);
%count_qtrs(2_13_d, outcome_2_13_d_step18);
%count_years(2_13_d, outcome_2_13_d_step20);
%count_state(2_13_d, outcome_2_13_d_step20);
%state_age(2_13_d, outcome_2_13_d_step20);
%state_gender(2_13_d, outcome_2_13_d_step20);
%community_gender(2_13_d, outcome_2_13_d_step20);
%community_age(2_13_d, outcome_2_13_d_step20);

/**********************************************************************************/
/*Outcome 2.13 combined    */
/**********************************************************************************/

data outcome_2_13_all_m;
length patient_id $100;
set outcome_2_13_a_step03 (in=a)
	outcome_2_13_b_step03 (in=b)
	outcome_2_13_c_step17 (in=c)
	outcome_2_13_d_step17 (in=d);

if a then outcome = 'A';
if b then outcome = 'B';
if c then outcome = 'C';
if d then outcome = 'D';

run;

proc sql;
create table outcome_2_13_all_m_unique as
select unique 	patient_id, 
				community, 
				year, 
				month
from outcome_2_13_all_m;
quit;



data outcome_2_13_all_q;
length patient_id $100;
set outcome_2_13_a_step04 (in=a)
	outcome_2_13_b_step04 (in=b)
	outcome_2_13_c_step18 (in=c)
	outcome_2_13_d_step18 (in=d);

if a then outcome = 'A';
if b then outcome = 'B';
if c then outcome = 'C';
if d then outcome = 'D';

run;

proc sql;
create table outcome_2_13_all_q_unique as
select unique 	patient_id, 
				community, 
				year, 
				quarter
from outcome_2_13_all_q;
quit;
proc options option=work; run;


data outcome_2_13_all_y;
length patient_id $100;
set outcome_2_13_a_step05 (in=a)
	outcome_2_13_b_step05 (in=b)
	outcome_2_13_c_step19 (in=c)
	outcome_2_13_d_step19 (in=d);

if a then outcome = 'A';
if b then outcome = 'B';
if c then outcome = 'C';
if d then outcome = 'D';

run;

proc sql;
create table outcome_2_13_all_y_unique as
select unique 	patient_id, 
				community, 
				year
from outcome_2_13_all_y;
quit;
/*************************************************************************************************/
/*************************************************************************************************/
/*************************************************************************************************/
/**/
/*NYS ADDITION AND EDIT:STEP 6 TO STARIFY FOR AGE AND GENDER FOR STATE AND COMMUNITY COUNTS;*/
/**/
/*************************************************************************************************/
/*************************************************************************************************/
/*************************************************************************************************/
proc sql;
create table outcome_2_13_all_y_unique_st as
SELECT a.* ,b.year_filled, b.date_filled as last_fill
FROM outcome_2_13_all_y_unique a
LEFT JOIN opioid_17_benzo_lastfill b
ON a.patient_id = b.patient_id and a.year=b.year_filled ;
quit;
proc sql;
create table outcome_2_13_all_y_unique_st2 as 
select 	a.patient_id, a.year,	a.last_fill,b.gender,b.dob,a.community,
int(yrdif(b.dob, a.last_fill,'ACTUAL')) as age_at_lastfill
from outcome_2_13_all_y_unique_st a left join pmp_gender_dob b
on a.patient_id = b.patient_id 	  ;
quit;
data outcome_2_13_all_y_unique_st1;
set outcome_2_13_all_y_unique_st2;
If gender not in ('1' '2') then gender  ='0';

if age_at_lastfill eq . then do;
age_at_lastfill=int(yrdif(dob, mdy(12,31,year),'ACTUAL'));
end;

if age_at_lastfill ne . and age_at_lastfill le 17 then delete;
else IF age_at_lastfill EQ . THEN age_cat=0;
else if 18<=age_at_lastfill<=34 then age_cat=1;
else if 35<=age_at_lastfill<=54 then age_cat=2;
else if age_at_lastfill ge 55 then age_cat=3;
format dob mmddyy10.;
run;
%count_months(2_13_all, outcome_2_13_all_m_unique);
%count_qtrs(2_13_all, outcome_2_13_all_q_unique);
%count_years(2_13_all, outcome_2_13_all_y_unique_st1);
%count_state(2_13_all, outcome_2_13_all_y_unique_st1);
%state_age(2_13_all, outcome_2_13_all_y_unique_st1);
%state_gender(2_13_all, outcome_2_13_all_y_unique_st1);
%community_gender(2_13_all, outcome_2_13_all_y_unique_st1);
%community_age(2_13_all, outcome_2_13_all_y_unique_st1);

/****************************************************************************************************/
/******************************************* Outcome 2.5.1 ******************************************/
/*NUMBER OF INDIVIDUALS RECEIVING BUPRENORPHINE PRODUCTS THAT ARE FDA-APPROVED FOR TREATMENT OF OUD*/
/****************************************************************************************************/
/****************************************************************************************************/
proc sql;
create table outcome_2_5_1_step01 as
select unique 	patient_id,
				year_filled as year,
				quarter_filled as quarter,	
			  	month_filled as month
from hcs_bup_18;
quit;
proc sql;
create table outcome_2_5_1_step02 as
select unique a.patient_id, a.year, a.month, b.community
from outcome_2_5_1_step01 a, step_j b
where 	a.patient_id = b.patient_id and
		a.year = b.year and 
		a.month = b.month;
quit;

proc sql;
create table outcome_2_5_1_step03 as
select unique a.patient_id, a.year, a.quarter, b.community
from outcome_2_5_1_step01 a, step_k b
where 	a.patient_id = b.patient_id and
		a.year = b.year and 
		a.quarter = b.quarter;
quit;

proc sql;
create table outcome_2_5_1_step04 as
select unique a.patient_id, a.year, b.community
from outcome_2_5_1_step01 a, step_l b
where 	a.patient_id = b.patient_id and
		a.year = b.year;
quit;
/*************************************************************************************************/
/*************************************************************************************************/
/*************************************************************************************************/
/**/
/*NYS ADDITION AND EDIT:STEP 6 TO STARIFY FOR AGE AND GENDER FOR STATE AND COMMUNITY COUNTS;*/
/**/
/*************************************************************************************************/
/*************************************************************************************************/
/*************************************************************************************************/
proc sql;
create table outcome_2_5_1_step05a as
SELECT a.* ,b.*
FROM outcome_2_5_1_step04 a
LEFT JOIN hcs_bup_18_lastfill b
ON a.patient_id = b.patient_id and a.year=b.year_filled ;
quit;

proc sql;
create table outcome_2_5_1_step05b as 
select 	a.patient_id, a.year,	a.last_fill,b.gender,b.dob,a.community,
int(yrdif(b.dob, a.last_fill,'ACTUAL')) as age_at_lastfill
from outcome_2_5_1_step05a a left join pmp_gender_dob b
on a.patient_id = b.patient_id 	  ;
quit;
data outcome_2_5_1_step05;
set outcome_2_5_1_step05b;
If gender not in ('1' '2')  then gender  ='0';
IF age_at_lastfill EQ . THEN age_cat=0;
else if 18<=age_at_lastfill<=34 then age_cat=1;
else if 35<=age_at_lastfill<=54 then age_cat=2;
else if age_at_lastfill ge 55 then age_cat=3;
run;
%count_months(2_5_1, outcome_2_5_1_step02);
%count_qtrs(2_5_1, outcome_2_5_1_step03);
%count_years(2_5_1, outcome_2_5_1_step05);
%count_state(2_5_1, outcome_2_5_1_step05);
%state_age(2_5_1, outcome_2_5_1_step05);
%state_gender(2_5_1, outcome_2_5_1_step05);
%community_gender(2_5_1, outcome_2_5_1_step05);
%community_age(2_5_1, outcome_2_5_1_step05);
/*******************************************************************************************/
/************************************** Outcome 2.7.1 **************************************/
/******NUMBER OF INDIVIDUALS RECEIVING BUPRENORPHINE/NALOXONE RETAINED BEYOND 6 MONTHS******/
/*******************************************************************************************/
/*******************************************************************************************/
data outcome_2_7_1_step01;
set hcs_bup_17_step12;
threshold_date = min_date_filled + 180;
format threshold_date date9.;
where duration ge 180;
run;

/*CREATING A NULL ROW*/
proc sql;
create table outcome_2_7_1_step02 as
select unique 	"xxxxxxxxx" as patient_id length=100, 
				0 as year,
				0 as quarter,
				0 as month
from first_and_last;
quit;



%macro retained_6mo(date);

proc sql noprint;
insert into outcome_2_7_1_step02
select unique 	patient_id,
				year(&date) as year,
				qtr(&date) as quarter,
				month(&date) as month
from outcome_2_7_1_step01
where threshold_date le &date le max_date_run_out
;
quit;

%mend retained_6mo;

/*NEW 20200501 to suppress notes in the log*/
options nomprint nosymbolgen nonotes nosource;
/*******************************************/
data _null_; 
set first_and_last;
call execute('%retained_6mo('||date||')');
run;
options mprint symbolgen notes source;
proc sql;
create table outcome_2_7_1_step03 as
select unique * 
from outcome_2_7_1_step02
where year ne 0;
quit;

proc sql;
create table outcome_2_7_1_step04 as 
select unique a.*,
			  b.year_18yo,
			  b.month_dob
from outcome_2_7_1_step03 a, pmp_dobs b
where a.patient_id = b.patient_id;
quit;

data outcome_2_7_1_step05; 
set outcome_2_7_1_step04;
if year lt year_18yo then delete;
if year eq year_18yo and month lt month_dob then delete;
run; 


proc sql;
create table outcome_2_7_1_step06 as 
select unique	a.patient_id,
				a.year,
				a.month,
				b.community
from outcome_2_7_1_step05 a, step_j b
where 	a.patient_id = b.patient_id and 
		a.year = b.year and
		a.month = b.month;
quit;

proc sql;
create table outcome_2_7_1_step07 as 
select unique 	a.patient_id,
				a.year,
				a.quarter,
				b.community
from outcome_2_7_1_step05 a, step_k b
where 	a.patient_id = b.patient_id and
		a.year = b.year and
		a.quarter = b.quarter;
quit;

proc sql;
create table outcome_2_7_1_step08 as 
select unique 	a.patient_id,
				a.year,
				b.community
from outcome_2_7_1_step05 a, step_l b
where 	a.patient_id = b.patient_id and
		a.year = b.year;
quit;
/*************************************************************************************************/
/*************************************************************************************************/
/*************************************************************************************************/
/**/
/*NYS ADDITION AND EDIT:STEP 6 TO STARIFY FOR AGE AND GENDER FOR STATE AND COMMUNITY COUNTS;*/
/**/
/*************************************************************************************************/
/*************************************************************************************************/
/*************************************************************************************************/
proc sql;
create table outcome_2_7_1_step09a as
SELECT a.* ,b.*
FROM outcome_2_7_1_step08 a
LEFT JOIN hcs_bup_17_lastfill b
ON a.patient_id = b.patient_id and a.year=b.year_filled ;
quit;
proc sql;
create table outcome_2_7_1_step09b as 
select 	a.patient_id, a.year,	a.last_fill,b.gender,b.dob,a.community,
int(yrdif(b.dob, a.last_fill,'ACTUAL')) as age_at_lastfill
from outcome_2_7_1_step09a a left join pmp_gender_dob b
on a.patient_id = b.patient_id 	  ;
quit;
data outcome_2_7_1_step09;
set outcome_2_7_1_step09b;
If gender not in ('1' '2') then gender  ='0';

if age_at_lastfill eq . then do;
age_at_lastfill=int(yrdif(dob, mdy(12,31,year),'ACTUAL'));
end;

IF age_at_lastfill NE . AND age_at_lastfill le 17 then delete;
else IF age_at_lastfill EQ . THEN age_cat=0;
else if 18<=age_at_lastfill<=34 then age_cat=1;
else if 35<=age_at_lastfill<=54 then age_cat=2;
else if age_at_lastfill ge 55 then age_cat=3;
format dob mmddyy10.;
run;
%count_months(2_7_1, outcome_2_7_1_step06);
%count_qtrs(2_7_1, outcome_2_7_1_step07);
%count_years(2_7_1, outcome_2_7_1_step09);
%count_state(2_7_1, outcome_2_7_1_step09);
%state_age(2_7_1, outcome_2_7_1_step09);
%state_gender(2_7_1, outcome_2_7_1_step09);
%community_gender(2_7_1, outcome_2_7_1_step09);
%community_age(2_7_1, outcome_2_7_1_step09);
/**************************************************************************************/
/************************************ Outcome 2.18 ************************************/
/***************NEW ACUTE OPIOID PRESCRIPTIONS LIMITED TO A 7 DAY SUPPLY***************/
/**************************************************************************************/
/**************************************************************************************/
data outcome_2_18_denom_step01; 
set hcs_opioid_18_step12;
year = year(min_date_filled);
quarter = qtr(min_date_filled);
month = month(min_date_filled);
where gap_prior ge 45;
run;
proc sql;
create table outcome_2_18_denom_step02 as
select unique 	patient_id, 
				year, 
				quarter, 
				month
from outcome_2_18_denom_step01;
quit;


proc sql;
create table outcome_2_18_denom_step03 as
select unique a.*, b.community
from outcome_2_18_denom_step02 a, step_j b
where 	a.patient_id = b.patient_id and
		a.year = b.year and 
		a.month = b.month;
quit;

proc sql;
create table outcome_2_18_denom_step04 as
select unique a.*, b.community
from outcome_2_18_denom_step02 a, step_k b
where 	a.patient_id = b.patient_id and
		a.year = b.year and 
		a.quarter = b.quarter;
quit;

proc sql;
create table outcome_2_18_denom_step05 as
select unique a.*, b.community
from outcome_2_18_denom_step02 a, step_l b
where 	a.patient_id = b.patient_id and
		a.year = b.year;
quit;
/*************************************************************************************************/
/*************************************************************************************************/
/*************************************************************************************************/
/**/
/*NYS ADDITION AND EDIT:STEP 6 TO STARIFY FOR AGE AND GENDER FOR STATE AND COMMUNITY COUNTS;*/
/**/
/*************************************************************************************************/
/*************************************************************************************************/
/*************************************************************************************************/
proc sql;
create table outcome_2_18_denom_step06a as
SELECT a.* ,b.*
FROM outcome_2_18_denom_step05 a
LEFT JOIN hcs_opioid_18_lastfill b
ON a.patient_id = b.patient_id and a.year=b.year_filled ;
quit;

proc sql;
create table outcome_2_18_denom_step06b as 
select 	a.patient_id, a.year,	a.last_fill,b.gender,b.dob,a.community,
int(yrdif(b.dob, a.last_fill,'ACTUAL')) as age_at_lastfill
from outcome_2_18_denom_step06a a left join pmp_gender_dob b
on a.patient_id = b.patient_id 	  ;
quit;
data outcome_2_18_denom_step06;
set outcome_2_18_denom_step06b;
If gender not in ('1' '2') then gender  ='0';
IF age_at_lastfill EQ . THEN age_cat=0;
else if 18<=age_at_lastfill<=34 then age_cat=1;
else if 35<=age_at_lastfill<=54 then age_cat=2;
else if age_at_lastfill ge 55 then age_cat=3;
run;
%count_months(2_18_denom, outcome_2_18_denom_step03);
%count_qtrs(2_18_denom, outcome_2_18_denom_step04);
%count_years(2_18_denom, outcome_2_18_denom_step06);
%count_state(2_18_denom, outcome_2_18_denom_step06);
%state_age(2_18_denom, outcome_2_18_denom_step06);
%state_gender(2_18_denom, outcome_2_18_denom_step06);
%community_gender(2_18_denom, outcome_2_18_denom_step06);
%community_age(2_18_denom, outcome_2_18_denom_step06);

data outcome_2_18_numer_step01; 
set hcs_opioid_18_step12;
year = year(min_date_filled);
quarter = qtr(min_date_filled);
month = month(min_date_filled);
where gap_prior ge 45;
run;

proc sql;
create table outcome_2_18_numer_step02 as 
select unique 	patient_id,
				year,
				quarter,
				month
from outcome_2_18_numer_step01
order by patient_id, year, quarter, month; 
quit;


/*it's possible that there are mulitple fills on the first day. find any where days dispensed are >7*/
/*do not sum across records. instead, query individual records*/
proc sql;
create table outcome_2_18_numer_step03 as
select unique 	a.patient_id,
				a.date_filled,
				a.year_filled as year,
				a.quarter_filled as quarter,
				a.month_filled as month,
				a.days_dispensed 
from hcs_opioid_18 a, outcome_2_18_numer_step01 b
where 	a.patient_id = b.patient_id and
		a.date_filled = b.min_date_filled and
		a.days_dispensed > 7;
quit;

proc sql;
create table outcome_2_18_numer_step04 as 
select unique 	patient_id,
				year,
				quarter,
				month
from outcome_2_18_numer_step03
order by patient_id, year, quarter, month;
quit;

/*step 02 all, step04 is start dates with a >7. step05 is start dates in step02 without being in step04*/
data outcome_2_18_numer_step05; merge outcome_2_18_numer_step02(in=a) outcome_2_18_numer_step04(in=b); by patient_id year quarter month; if a and not b; run;


proc sql;
create table outcome_2_18_numer_step06 as
select unique a.*, b.community
from outcome_2_18_numer_step05 a, step_j b
where 	a.patient_id = b.patient_id and
		a.year = b.year and 
		a.month = b.month;
quit;

proc sql;
create table outcome_2_18_numer_step07 as
select unique a.*, b.community
from outcome_2_18_numer_step05 a, step_k b
where 	a.patient_id = b.patient_id and
		a.year = b.year and 
		a.quarter = b.quarter;
quit;

proc sql;
create table outcome_2_18_numer_step08 as
select unique a.*, b.community
from outcome_2_18_numer_step05 a, step_l b
where 	a.patient_id = b.patient_id and
		a.year = b.year;
quit;
/*************************************************************************************************/
/*************************************************************************************************/
/*************************************************************************************************/
/**/
/*NYS ADDITION AND EDIT:STEP 6 TO STARIFY FOR AGE AND GENDER FOR STATE AND COMMUNITY COUNTS;*/
/**/
/*************************************************************************************************/
/*************************************************************************************************/
/*************************************************************************************************/
proc sql;
create table outcome_2_18_numer_step09a as
SELECT a.* ,b.*
FROM outcome_2_18_numer_step08 a
LEFT JOIN hcs_opioid_18_lastfill b
ON a.patient_id = b.patient_id and a.year=b.year_filled ;
quit;
proc sql;
create table outcome_2_18_numer_step09b as 
select 	a.patient_id, a.year,	a.last_fill,b.gender,b.dob,a.community,
int(yrdif(b.dob, a.last_fill,'ACTUAL')) as age_at_lastfill
from outcome_2_18_numer_step09a a left join pmp_gender_dob b
on a.patient_id = b.patient_id 	  ;
quit;
data outcome_2_18_numer_step09;
set outcome_2_18_numer_step09b;
If gender not in ('1' '2') then gender  ='0';
IF age_at_lastfill EQ . THEN age_cat=0;
else if 18<=age_at_lastfill<=34 then age_cat=1;
else if 35<=age_at_lastfill<=54 then age_cat=2;
else if age_at_lastfill ge 55 then age_cat=3;
run;
%count_months(2_18_numer, outcome_2_18_numer_step06);
%count_qtrs(2_18_numer, outcome_2_18_numer_step07);
%count_years(2_18_numer, outcome_2_18_numer_step09);
%count_state(2_18_numer, outcome_2_18_numer_step09);
%state_age(2_18_numer, outcome_2_18_numer_step09);
%state_gender(2_18_numer, outcome_2_18_numer_step09);
%community_gender(2_18_numer, outcome_2_18_numer_step09);
%community_age(2_18_numer, outcome_2_18_numer_step09);

/******************************************************************************************/
/************************************** Outcome 3.1 ***************************************/
/***************OPIOID PRESCRIPTIONS FROM MULTIPLE PRESCRIBERS OR PHARMACIES***************/
/******************************************************************************************/
/******************************************************************************************/

proc sql;
create table outcome_3_1_step01 as
select unique 	patient_id, 
				date_filled,
				dea_prescriber, 
				dea_pharmacy
from hcs_opioid_17;
quit;


/*2.Using the start date and end date defined in step A on page 1, create a table that includes the start date and end date of each moving quarter.*/

proc sql;
create table outcome_3_1_step02 as
select 	a.year,
		a.month,
		min(b.date) as month_start format date9.,
		max(b.date) as month_end format date9.
from months a, date_range b
where a.complete = 1 and a.month = month(b.date) and a.year = year(b.date)
group by a.year, a.month;
quit;


proc sql;
create table outcome_3_1_step03 as 
select 	b.year as year_mov_quarter_end,
		b.month as month_mov_quarter_end,
		a.month_start as mov_quarter_start format date9.,
		b.month_end as mov_quarter_end format date9.
from outcome_3_1_step02 a, outcome_3_1_step02 b
where 80 le (b.month_end - a.month_start) le 100;
quit;

proc sql;
create table outcome_3_1_step04 as 
select unique	b.patient_id,
				count(unique b.dea_prescriber) as prescriber_count,
				count(unique b.dea_pharmacy) as pharmacy_count,
				a.*
from outcome_3_1_step03 a, outcome_3_1_step01 b
where 	b.date_filled ge a.mov_quarter_start and
		b.date_filled le a.mov_quarter_end
group by b.patient_id, a.year_mov_quarter_end, a.month_mov_quarter_end;
quit;

data outcome_3_1_step05;
set outcome_3_1_step04;
if prescriber_count ge 4 or pharmacy_count ge 4 then measure_flag = 1;
if prescriber_count lt 4 and pharmacy_count lt 4 then measure_flag = 0;
run;


proc sql;
create table outcome_3_1_step06 as
select 	a.*,
		b.year_18yo, 
		b.month_dob
from outcome_3_1_step05 a, pmp_dobs b 
where 	a.patient_id = b.patient_id and
		(a.year_mov_quarter_end ge b.year_18yo or (a.year_mov_quarter_end eq b.year_18yo and a.month_mov_quarter_end ge b.month_dob));
quit;

proc sql; 
create table outcome_3_1_step07 as 
select unique 	patient_id, 
				year_mov_quarter_end as year, 
				month_mov_quarter_end as month
from outcome_3_1_step06
where measure_flag = 1;
quit;


/*new in version 13*/
/*From the table created in step 6, */
/*flag calendar quarters that include one or more*/
/*months where the 3.1 flag = 1.*/

data outcome_3_1_step08;
set outcome_3_1_step07;
if month in (1,2,3) then quarter = 1;
if month in (4,5,6) then quarter = 2;
if month in (7,8,9) then quarter = 3;
if month in (10,11,12) then quarter = 4;
run;

proc sql;
create table outcome_3_1_step09 as
select unique 	patient_id, 
				year, 
				quarter
from outcome_3_1_step08
where quarter ne .;
quit;

proc sql;
create table outcome_3_1_step10 as
select unique 	patient_id, 
				year
from outcome_3_1_step09;
quit;


proc sql;
create table outcome_3_1_step11 as 
select unique 	a.patient_id,
				a.year,
				a.month,
				b.community
from outcome_3_1_step07 a, step_j b
where a.patient_id = b.patient_id and
	  a.year = b.year and
	  a.month = b.month;
quit;

proc sql;
create table outcome_3_1_step12 as 
select unique  	a.patient_id,
				a.year,
				a.quarter,
				b.community
from outcome_3_1_step09 a, step_k b
where a.patient_id = b.patient_id and
	  a.year = b.year and
	  a.quarter = b.quarter;
quit;

proc sql;
create table outcome_3_1_step13 as 
select unique	a.patient_id,
				a.year,
				b.community
from outcome_3_1_step10 a, step_l b
where a.patient_id = b.patient_id and
	  a.year = b.year;
quit;

/*************************************************************************************************/
/*************************************************************************************************/
/*************************************************************************************************/
/**/
/*NYS ADDITION AND EDIT:STEP 6 TO STARIFY FOR AGE AND GENDER FOR STATE AND COMMUNITY COUNTS;*/
/**/
/*************************************************************************************************/
/*************************************************************************************************/
/*************************************************************************************************/
proc sql;
create table outcome_3_1_step14a as
SELECT a.* ,b.*
FROM outcome_3_1_step13 a
LEFT JOIN hcs_opioid_17_lastfill b
ON a.patient_id = b.patient_id and a.year=b.year_filled ;
quit;
proc sql;
create table outcome_3_1_step14b as 
select 	a.patient_id, a.year,	a.last_fill,b.gender,b.dob,a.community,
int(yrdif(b.dob, a.last_fill,'ACTUAL')) as age_at_lastfill
from outcome_3_1_step14a a left join pmp_gender_dob b
on a.patient_id = b.patient_id 	  ;
quit;
data outcome_3_1_step14;
set outcome_3_1_step14b;
If gender not in ('1' '2') then gender  ='0';

if age_at_lastfill eq . then do;
age_at_lastfill=int(yrdif(dob, mdy(12,31,year),'ACTUAL'));
end;

IF age_at_lastfill ne . and age_at_lastfill le 17 then delete;
else IF age_at_lastfill eq . THEN age_cat=0;
else if 18<=age_at_lastfill<=34 then age_cat=1;
else if 35<=age_at_lastfill<=54 then age_cat=2;
else if age_at_lastfill ge 55 then age_cat=3;
run;
%count_months(3_1, outcome_3_1_step11);
%count_qtrs(3_1, outcome_3_1_step12);
%count_years(3_1, outcome_3_1_step14);
%count_state(3_1, outcome_3_1_step14);
%state_age(3_1, outcome_3_1_step14);
%state_gender(3_1, outcome_3_1_step14);
%community_gender(3_1, outcome_3_1_step14);
%community_age(3_1, outcome_3_1_step14);

%macro set_counts(newvar, measure);

%macro sup(cat);
proc sort data= outcome_&measure._&cat; by community year patient_count; run;
data outcome_&measure._&cat.2;
      set outcome_&measure._&cat ;
by community year;
      if first.year then order=1;
      else order+1;
      if patient_count in (1,2,3,4,5) then sup = '1'; 
	  sup1=lag(sup);
      *if not first.year then sup1=lag(sup);
      *if sup1='1' and sup^='1' and order=2 then sup='1';
      *drop sup1 order;
if sup eq '1' or sup1 eq '1' then suppressed = 's';
drop sup sup1 order;
run;

/*proc sort data= outcome_&measure._&cat.2 out=outcome_&measure._&cat ; */
/*by community year &cat;*/
/*run;*/

%mend;

%sup(cage)
%sup(cgender)
%sup(sage)
%sup(sgender)


data outcome_&measure._counts; 
length community $100 year quarter month age_cat 8. gender $1. Stratification $20. ReporterId $10;
set outcome_&measure._counts_m 
	outcome_&measure._counts_q 
	outcome_&measure._counts_y
    outcome_&measure._state
    outcome_&measure._cage2
    outcome_&measure._cgender2 
    outcome_&measure._sage2
    outcome_&measure._sgender2; 

if patient_count in (1,2,3,4,5) or suppressed eq 's' then issuppressed = '1';
/*else if patient_count = 0 or patient_count ge 6 then*/ &newvar = patient_count;
*if issuppressed ne '1' then &newvar = patient_count;
*if patient_count in (1,2,3,4,5) then issuppressed = '1';

if age_cat eq 0 then Stratification=quote('Age')|| ":" || quote('Missing');
if age_cat eq 1 then Stratification=quote('Age')|| ":" || quote('18-34');
if age_cat eq 2 then Stratification=quote('Age')|| ":" || quote('35-54');
if age_cat eq 3 then Stratification=quote('Age')|| ":" || quote('55+');
if gender eq '0' then Stratification=quote('Gender')|| ":" || quote('Missing');
if gender eq '1' then Stratification=quote('Gender')|| ":" || quote('Male');
if gender eq '2' then Stratification=quote('Gender')|| ":" || quote('Female');


if community="Broome" then ReporterId ="0333";
if community="Cayuga" then ReporterId ="0334";
if community="Chautauqua" then ReporterId ="0335";
if community="Columbia" then ReporterId ="0336";
if community="Cortland" then ReporterId ="0337";
if community="Erie" then ReporterId ="0368";
if community="Buffalo" then ReporterId ="0338";
if community="Genesee" then ReporterId ="0339";
if community="Greene" then ReporterId ="0340";
if community="Lewis" then ReporterId ="0341";
if community="Monroe" then ReporterId ="0369";
if community="Rochester" then ReporterId ="0342";
if community="Orange" then ReporterId ="0343";
if community="Putnam" then ReporterId ="0344";
if community="Suffolk" then ReporterId ="0370";
if community="Brookhaven Township" then ReporterId ="0345";
if community="Sullivan" then ReporterId ="0346";
if community="Ulster" then ReporterId ="0347";
if community="Yates" then ReporterId ="0348";
if community="New York State" then ReporterId ="0300";

if community in ("Broome" "Cayuga" "Chautauqua" "Columbia" "Cortland"  
"Genesee" "Greene" "Lewis"  "Orange" "Putnam"  "Sullivan" "Ulster" "Yates" 
"New York State" 'Suffolk' 'Erie' 'Monroe' 'Rochester' 'Brookhaven Township' 'Buffalo' );

if year eq 2023;


/**code to test;*/
/**/
/*if community in ( 'Rest of Monroe' 'Rest of Erie' 'Rest of Suffolk' 'Suffolk' 'Erie' 'Monroe' 'Rochester' 'Brookhaven Township' 'Buffalo' );*/
/**/
/*if year eq 2017;*/

drop patient_count age_cat gender suppressed;
run;

proc sort data=outcome_&measure._counts; by community year quarter month; run;

/*data test.outcome_&measure._&sysdate.;*/
/*set outcome_&measure._counts;*/
/*run;*/

%mend set_counts;
%set_counts(numerator, 2_5_1);
%set_counts(numerator, 2_7_1);
%set_counts(numerator, 2_13_a);
%set_counts(numerator, 2_13_b);
%set_counts(numerator, 2_13_c);
%set_counts(numerator, 2_13_d);
%set_counts(numerator, 2_13_all);
%set_counts(numerator, 2_18_numer);
%set_counts(denominator, 2_18_denom);
%set_counts(numerator, 3_1);

proc sort data=outcome_2_18_numer_counts;
by community year quarter month Stratification issuppressed;
run;
proc sort data=outcome_2_18_denom_counts;
by community year quarter month Stratification issuppressed;
run;
data outcome_2_18_counts; 
merge outcome_2_18_numer_counts outcome_2_18_denom_counts ; 
by community year quarter month Stratification; 
run;

proc sort data=outcome_2_18_counts; by community year quarter month; run;

 
proc sql;
create table for_incomplete as
select unique (&end_date - 27) as end_minus_27 format date9.,
		year(&end_date - 27) as year_for_incomplete,
		qtr(&end_date - 27) as quarter_for_incomplete,
		month(&end_date - 27) as month_for_incomplete
from months;*dummy dataset;
run;



%macro incomp(measure);

proc sql;
create table outcome_&measure._counts_revised0
as select *
from outcome_&measure._counts, for_incomplete;
quit;

data outcome_&measure._counts_revised;
set outcome_&measure._counts_revised0;

/*yearly*/
if month = . and quarter = . then do;
	if year ge year_for_incomplete then complete = 0;
end;

/*quarterly*/
if quarter ne . then do;
	if year > year_for_incomplete then complete = 0;
	if year = year_for_incomplete and quarter ge quarter_for_incomplete then complete = 0;
end;

/*monthly*/
if month ne . then do;
	if year > year_for_incomplete then complete = 0;
	if year = year_for_incomplete and month ge month_for_incomplete then complete = 0;
end;

drop end_minus_27 year_for_incomplete quarter_for_incomplete month_for_incomplete;
run;
%mend incomp;

%incomp(2_13_a);
%incomp(2_13_all);

/**proc export data=outcome_2_5_1_counts outfile="E:\Anil\HEALing test\hcs_pmp_251_&rundate..xlsx" dbms=xlsx replace; 	*sheet=hcs_2_5_1; run;*/
/*************************************************************************************************************************/
/****************************The PROC EXPORTs below will produce one file with multiple tables****************************/
/*****************************Set the &export_path macro variable at the top of the program ******************************/
/*************************************************************************************************************************/

proc export data=outcome_2_5_1_counts outfile="&export_path.\hcs_pmp_measures_&rundate..xlsx" dbms=xlsx replace; 	sheet=hcs_2_5_1; run;
proc export data=outcome_2_7_1_counts outfile="&export_path.\hcs_pmp_measures_&rundate..xlsx" dbms=xlsx replace; 	sheet=hcs_2_7_1; run;
proc export data=outcome_2_13_a_counts_revised outfile="&export_path.\hcs_pmp_measures_&rundate..xlsx" dbms=xlsx replace; 	sheet=hcs_2_13A; run;
proc export data=outcome_2_13_b_counts outfile="&export_path.\hcs_pmp_measures_&rundate..xlsx" dbms=xlsx replace; 	sheet=hcs_2_13B; run;
proc export data=outcome_2_13_c_counts outfile="&export_path.\hcs_pmp_measures_&rundate..xlsx" dbms=xlsx replace; 	sheet=hcs_2_13C; run;
proc export data=outcome_2_13_d_counts outfile="&export_path.\hcs_pmp_measures_&rundate..xlsx" dbms=xlsx replace; 	sheet=hcs_2_13D; run;
proc export data=outcome_2_13_all_counts_revised outfile="&export_path.\hcs_pmp_measures_&rundate..xlsx" dbms=xlsx replace; sheet=hcs_2_13_combined; run;
proc export data=outcome_2_18_counts outfile="&export_path.\hcs_pmp_measures_&rundate..xlsx" dbms=xlsx replace; sheet=hcs_2_18; run;
proc export data=outcome_3_1_counts outfile="&export_path.\hcs_pmp_measures_&rundate..xlsx" dbms=xlsx replace; 	sheet=hcs_3_1; run;
/*proc export data=final outfile="&export_path.\hcs_pmp_measure3_3_&rundate..xlsx" dbms=xlsx replace; sheet=hcs_3_3; run;

