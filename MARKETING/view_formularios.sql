/*Este código se encarga de crear un view con información requerida
para el análisis de la data de formularios alojados en Hubspot*/
--Desarrollado por Sebastián Navarrete
--Data Cloud Engineer
--Interlat Colombia

-- CONFIGURACIÓN DE ENTORNO DE TRABAJO
USE ROL ACCOUNTADMIN;      --usar el rol 'ACCOUNTADMIN'
USE WAREHOUSE INTERLAT_WH; --usar el warehouse 'INTERLAT_WH'
USE DATABASE INTERLAT_DB;  --usar la base de datos 'INTERLAT_DB'
USE SCHEMA MARKETING;      --usar el esquema 'MARKETING'

-- FUNCIÓN PARA CORREGIR NOMBRE DE FORMULARIOS
-- Esta función toma una parte de la cadena de caracteres del nombre del formulario
-- para realizar una unión de datos de HUbspot y de Google Analytics.
-- La funcíon recibe una cadena de caracteres con un caracater de separación
-- que sirve de guía para separar la cadena y tomar el nombre del formulario.
CREATE OR REPLACE FUNCTION "SBSTR_FN"("NAME" VARCHAR(16777216))
RETURNS VARCHAR(16777216)
LANGUAGE JAVASCRIPT -- La función se desarrolla en JavaScript
AS '
if (NAME.indexOf("-") > -1) {
    return NAME.substring(0,NAME.indexOf("-")-1);   
} else if (NAME.indexOf("|") > -1) {
    return NAME.substring(0,NAME.indexOf("|")-1);
} else {
    return NAME;
}
';
-- DATA POWERBI FORMULARIOS
-- El view contiene la UNION de las métricas de Google Anlytics y Los registros de formularios
-- alojados en Hubspot
-- Data de Google Analytics: DATE, PAGE_TITLE, PAGEVIEWS, AVD_TIME_ON_PAGE, UNIQUE_PAGEVIEWS, EXITS, ENTRANCES, BOUNCES, URL
-- Data de Hubspot: FORM_NAME, FORM_ID, REGISTERED
CREATE OR REPLACE VIEW FORMS_DATA_POWERBI AS
SELECT A.DATE, PAGE_TITLE, TITLE AS FORM_NAME, PAGEVIEWS, AVG_TIME_ON_PAGE, UNIQUE_PAGEVIEWS, EXITS, ENTRANCES, BOUNCES , REG.FORM_ID ,
 REG.REGISTERED, URL FROM interlat_db.marketing.traffic AS A
LEFT JOIN (SELECT CAST(TIMESTAMP AS DATE) AS DATE, SBSTR_FN(TITLE) AS TITLE, FORM_ID , COUNT(FORM_ID) as REGISTERED FROM INTERLAT_DB.HUBSPOT.CONTACT_FORM_SUBMISSION
WHERE TITLE LIKE 'Solicitar%' OR TITLE LIKE '%Interlat Contacto%' OR TITLE LIKE '%Newsletter%' 
OR TITLE LIKE'%Guía #%' OR TITLE LIKE '%Caso de Éxito #%' OR TITLE LIKE '%Caso de Uso #%' 
OR TITLE LIKE '%Ebook #%' OR TITLE LIKE '%Gira #%'
GROUP BY TITLE, DATE, form_id) AS REG ON A.DATE = REG.DATE and SBSTR_FN(PAGE_TITLE) = REG.TITLE
WHERE PAGE_TITLE LIKE 'Solicitar%' OR PAGE_TITLE LIKE '%Interlat Contacto%' OR PAGE_TITLE LIKE '%Newsletter%' 
OR PAGE_TITLE LIKE'%Guía #%' OR PAGE_TITLE LIKE '%Caso de Éxito #%' OR PAGE_TITLE LIKE '%Caso de Uso #%' 
OR PAGE_TITLE LIKE '%Ebook #%' OR TITLE LIKE '%Gira #%'
ORDER BY DATE DESC;

SELECT * FROM FORMS_DATA_POWERBI;
