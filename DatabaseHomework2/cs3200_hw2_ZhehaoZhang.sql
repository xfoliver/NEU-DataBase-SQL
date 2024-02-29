-- CS3200: Database Design
-- GAD: The Genetic Association Database


-- Write a query to answer each of the following questions
-- Save your script file as cs3200_hw2_yourname.sql (no spaces)
-- Submit this file for your homework submission

show variables where variable_name like 'local_infile';
set global local_infile=ON;

-- create gad database
DROP DATABASE IF EXISTS gad;
CREATE DATABASE gad;

-- make gad the active database
USE gad;

DROP TABLE IF EXISTS gad;
CREATE TABLE gad (
  gad_id int,
  association text,
  phenotype text,
  disease_class text,
  chromosome text,
  chromosome_band text,
  dna_start int,
  dna_end int,
  gene text,
  gene_name text,
  reference text,
  pubmed_id int,
  year int,
  population text
) ;

TRUNCATE gad;
LOAD DATA LOCAL
INFILE 'C:/Users/OliverZhang/courses/cs3200/hw/hw2/gad.csv'
INTO TABLE gad
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
IGNORE 1 ROWS;

SELECT count(*) FROM gad;
SELECT * FROM gad;


-- 1. 
-- Explore the content of the various columns in your gad table.
-- List all genes that are "G protein-coupled" receptors in alphabetical order by gene symbol
-- Output the gene symbol, gene name, and chromosome
-- (These genes are often the target for new drugs, so are of particular interest)

SELECT gene, gene_name, chromosome
FROM gad
WHERE gene_name LIKE '%G protein-coupled%'
ORDER BY gene;



-- 2. 
-- How many records are there for each disease class?
-- Output your list from most frequent to least frequent
 
SELECT disease_class, COUNT(*) AS number_of_records
FROM gad
GROUP BY disease_class
ORDER BY number_of_records DESC;


-- 3. 
-- List all distinct phenotypes related to the disease class "IMMUNE"
-- Output your list in alphabetical order
SELECT DISTINCT phenotype
FROM gad
WHERE disease_class = 'IMMUNE'
ORDER BY phenotype ASC;


-- 4.
-- Show the immune-related phenotypes
-- based on the number of records reporting a positive association with that phenotype.
-- Display both the phenotype and the number of records with a positive association
-- Only report phenotypes with at least 60 records reporting a positive association.
-- Your list should be sorted in descending order by number of records
-- Use a column alias: "num_records"

SELECT phenotype, COUNT(*) AS num_records
FROM gad
WHERE disease_class = 'IMMUNE' AND association = 'Y'
GROUP BY phenotype
HAVING num_records >= 60
ORDER BY num_records DESC;


-- 5.
-- List the gene symbol, gene name, and chromosome attributes related
-- to genes positively linked to asthma (association = Y).
-- Include in your output any phenotype containing the substring "asthma"
-- List each distinct record once
-- Sort  gene symbol

SELECT DISTINCT gene, gene_name, chromosome
FROM gad
WHERE association = 'Y' AND phenotype LIKE '%asthma%'
ORDER BY gene;



-- 6. 
-- For each chromosome, over what range of nucleotides do we find
-- genes mentioned in GAD?
-- Exclude cases where the dna_start value is 0 or where the chromosome is unlisted.
-- Sort your data by chromosome. Don't be concerned that
-- the chromosome values are TEXT. (1, 10, 11, 12, ...)

SELECT chromosome, MIN(dna_start) AS min_start, MAX(dna_end) AS max_end
FROM gad
WHERE dna_start != 0 AND chromosome IS NOT NULL AND chromosome != ''
GROUP BY chromosome
ORDER BY chromosome;



-- 7 
-- For each gene, what is the earliest and latest reported year
-- involving a positive association
-- Ignore records where the year isn't valid. (Explore the year column to determine what constitutes a valid year.)
-- Output the gene, min-year, max-year, and number of GAD records
-- order from most records to least.
-- Columns with aggregation functions should be aliased

SELECT gene, MIN(year) AS min_year, MAX(year) AS max_year, COUNT(*) AS gad_records_count
FROM gad
WHERE association = 'Y' 
GROUP BY gene
ORDER BY gad_records_count DESC;



-- 8. 
-- Which genes have a total of at least 100 positive association records (across all phenotypes)?
-- Give the gene symbol, gene name, and the number of associations
-- Use a 'num_records' alias in your query wherever possible
SELECT gene AS gene_symbol, gene_name, COUNT(*) AS num_records
FROM gad
WHERE association = 'Y'
GROUP BY gene, gene_name
HAVING num_records >= 100
ORDER BY num_records DESC;



-- 9. 
-- How many total GAD records are there for each population group?
-- Sort in descending order by count
-- Show only the top five results based on number of records
-- Do NOT include cases where the population is blank

SELECT population, COUNT(*) AS num_records
FROM gad
WHERE population IS NOT NULL AND population != ''
GROUP BY population
ORDER BY num_records DESC
LIMIT 5;



-- 10. 
-- In question 5, we found asthma-linked genes
-- But these genes might also be implicated in other diseases
-- Output gad records involving a positive association between ANY asthma-linked gene and ANY disease/phenotype
-- Sort your output alphabetically by phenotype
-- Output the gene, gene_name, association (should always be 'Y'), phenotype, disease_class, and population
-- Hint: Use a subselect in your WHERE class and the IN operator

SELECT 
    gene,
    gene_name,
    association,
    phenotype,
    disease_class,
    population
FROM gad
WHERE association = 'Y' 
AND gene IN (
    SELECT DISTINCT gene
    FROM gad
    WHERE association = 'Y' AND phenotype LIKE '%asthma%'
)
ORDER BY phenotype;



-- 11. 
-- Modify your previous query.
-- Let's count how many times each of these asthma-gene-linked phenotypes occurs
-- in our output table produced by the previous query.
-- Output just the phenotype, and a count of the number of occurrences for the top 5 phenotypes
-- with the most records involving an asthma-linked gene (EXCLUDING asthma itself).

SELECT 
    phenotype, COUNT(*) AS num_occurrences
FROM gad
WHERE association = 'Y' 
AND gene IN (
    SELECT DISTINCT gene
    FROM gad
    WHERE association = 'Y' AND phenotype LIKE '%asthma%'
)
AND phenotype NOT LIKE '%asthma%'
GROUP BY phenotype
ORDER BY phenotype DESC
LIMIT 5;



-- 12. 
-- Interpret your analysis

-- a) Search the Internet. Does existing biomedical research support a connection between asthma and the
-- top phenotype you identified above? Cite some sources and justify your conclusion!

-- ANSWER:
SELECT DISTINCT gene, gene_name, phenotype, chromosome
FROM gad
WHERE association = 'Y' AND phenotype LIKE '%asthma%'
ORDER BY gene DESC;

-- According to above code, we can find the gene that strong connect with Asthma is TNF. According 
-- to current medical research, TNF is beneficial in initiating inflammatory responses, but excessive 
-- and sustained TNF production can lead to chronic inflammation and related diseases, asthma being 
-- one of them. Because asthma is a chronic allergic inflammation of the airways. In the article 
-- Research Progress on the Relationship between TNF-α and Asthma, Gao Jinming and other experts 
-- used the polymerase chain reaction-restricted length polymorphism (PCR-RFLP) method to explore 
-- TNF-α gene polymorphisms and genetic susceptibility to asthma. The relationship between asthma 
-- phenotypes, the results showed that the frequency of TNF-α22 homozygotes in the asthma group was as 
-- high as 20.8%, and the allele frequency was 0.42, which was significantly higher than that in the 
-- healthy control group. Therefore, TNF is indeed one of the main factors causing asthma. Combined 
-- with the results output by the above code, it can be confirmed that the connection between asthma 
-- and the top phenotype (TNF) is reliable.

-- CIATION:
-- Department(no name). "TNF-α与哮喘的关系研究进展." 专业文章（Professional Artical）website. June.2012 
-- website: https://article.iiyi.com/detail/32418.html
-- 
-- Erwin W. Gelfand, MD. "Inflammation, Asthma, and Tumor Necrosis Factor-alpha." Mediscape Allergy & Immunology. (no date)
-- website: https://www.medscape.org/viewarticle/555292#:~:text=Among%20the%20candidates%20identified%20as%20perhaps%20playing%20a,%28BAL%29%20fluid%20from%20patients%20with%20more%20severe%20asthma.


-- b) Why might a drug company be interested in instances of such "overlapping" phenotypes?

-- ANSWER:
-- Overlapping phenotypes imply a link between a gene and several different diseases. This means that 
-- treatments targeting this gene may have an effect on multiple diseases at the same time. Therefore, 
-- there will be a larger market for drugs made against this gene. In addition, when conducting drug 
-- research on genes with overlapping phenotypes, the research cost of drugs will be relatively low, 
-- because overlapping phenotypes are associated with multiple diseases, so only one gene needs to be 
-- studied during the research process, and More drugs can be produced for different diseases. So, because
-- of these two factors can let drug company get more revenue,so, the drug company is interested in 
-- instances of such "overlapping" phenotypes.


-- CONGRATULATIONS!!: YOU JUST DID SOME LEGIT DRUG DISCOVERY RESEARCH! :-)
