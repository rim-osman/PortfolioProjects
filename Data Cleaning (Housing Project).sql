/*

Data Cleaning in SQL 

*/


-- Check the DATABASE

Select *
FROM nashville_housing;
 
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 

-- Standardize Date Format 

SELECT 
  SaleDate,
  CASE
    WHEN SaleDate LIKE 'January%'   THEN printf('%s-01-%02d', substr(SaleDate, -4), CAST(substr(SaleDate, instr(SaleDate, ' ')+1, instr(SaleDate, ',') - instr(SaleDate, ' ') - 1) AS INT))
    WHEN SaleDate LIKE 'February%'  THEN printf('%s-02-%02d', substr(SaleDate, -4), CAST(substr(SaleDate, instr(SaleDate, ' ')+1, instr(SaleDate, ',') - instr(SaleDate, ' ') - 1) AS INT))
    WHEN SaleDate LIKE 'March%'     THEN printf('%s-03-%02d', substr(SaleDate, -4), CAST(substr(SaleDate, instr(SaleDate, ' ')+1, instr(SaleDate, ',') - instr(SaleDate, ' ') - 1) AS INT))
    WHEN SaleDate LIKE 'April%'     THEN printf('%s-04-%02d', substr(SaleDate, -4), CAST(substr(SaleDate, instr(SaleDate, ' ')+1, instr(SaleDate, ',') - instr(SaleDate, ' ') - 1) AS INT))
    WHEN SaleDate LIKE 'May%'       THEN printf('%s-05-%02d', substr(SaleDate, -4), CAST(substr(SaleDate, instr(SaleDate, ' ')+1, instr(SaleDate, ',') - instr(SaleDate, ' ') - 1) AS INT))
    WHEN SaleDate LIKE 'June%'      THEN printf('%s-06-%02d', substr(SaleDate, -4), CAST(substr(SaleDate, instr(SaleDate, ' ')+1, instr(SaleDate, ',') - instr(SaleDate, ' ') - 1) AS INT))
    WHEN SaleDate LIKE 'July%'      THEN printf('%s-07-%02d', substr(SaleDate, -4), CAST(substr(SaleDate, instr(SaleDate, ' ')+1, instr(SaleDate, ',') - instr(SaleDate, ' ') - 1) AS INT))
    WHEN SaleDate LIKE 'August%'    THEN printf('%s-08-%02d', substr(SaleDate, -4), CAST(substr(SaleDate, instr(SaleDate, ' ')+1, instr(SaleDate, ',') - instr(SaleDate, ' ') - 1) AS INT))
    WHEN SaleDate LIKE 'September%' THEN printf('%s-09-%02d', substr(SaleDate, -4), CAST(substr(SaleDate, instr(SaleDate, ' ')+1, instr(SaleDate, ',') - instr(SaleDate, ' ') - 1) AS INT))
    WHEN SaleDate LIKE 'October%'   THEN printf('%s-10-%02d', substr(SaleDate, -4), CAST(substr(SaleDate, instr(SaleDate, ' ')+1, instr(SaleDate, ',') - instr(SaleDate, ' ') - 1) AS INT))
    WHEN SaleDate LIKE 'November%'  THEN printf('%s-11-%02d', substr(SaleDate, -4), CAST(substr(SaleDate, instr(SaleDate, ' ')+1, instr(SaleDate, ',') - instr(SaleDate, ' ') - 1) AS INT))
    WHEN SaleDate LIKE 'December%'  THEN printf('%s-12-%02d', substr(SaleDate, -4), CAST(substr(SaleDate, instr(SaleDate, ' ')+1, instr(SaleDate, ',') - instr(SaleDate, ' ') - 1) AS INT))
  END AS Sale_Date
FROM nashville_housing;

- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 

-- Populate  Property Address Data 

SELECT*
FROM nashville_housing
-- WHERE PropertyAddress is Null
ORDER by ParcelID;

SELECT a.ParcelID, 
				a.PropertyAddress, 
				b.ParcelID, 
				b.PropertyAddress, 
				ifnull(a.PropertyAddress, b.PropertyAddress) as MergedAddress
FROM nashville_housing as a 
JOIN nashville_housing as b 
	ON a.ParcelID = b.ParcelID
	AND a.UniqueID <> b.UniqueID
WHERE a.PropertyAddress is NULL; 

UPDATE nashville_housing
SET PropertyAddress = (
  SELECT b.PropertyAddress
  FROM nashville_housing AS b
  WHERE b.ParcelID = nashville_housing.ParcelID
    AND b.UniqueID <> nashville_housing.UniqueID
    AND b.PropertyAddress IS NOT NULL
  LIMIT 1
)
WHERE PropertyAddress IS NULL;

- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 

-- Breaking out Address into Individual Columns (Address, City, State)  

SELECT PropertyAddress
FROM nashville_housing
-- WHERE PropertyAddress is Null
-- ORDER by ParcelID;

SELECT
substr(propertyAddress, 1, instr(PropertyAddress, ',') -1) as StreetAddress,
substr(propertyAddress, instr(PropertyAddress, ',') +1) as City
FROM nashville_housing;


-- Add New Columns 

ALTER TABLE nashville_housing
Add COLUMN Property_Address TEXT;

ALTER TABLE nashville_housing 
ADD COLUMN Property_City TEXT;

-- Update the New Columns 

UPDATE nashville_housing
SET Property_Address = substr(propertyAddress, 1, instr(PropertyAddress, ',') -1);

UPDATE nashville_housing
SET Property_City = substr(propertyAddress, instr(PropertyAddress, ',') +1) ; 


-- Check the New Columns in the Table 

SELECT*
FROM nashville_housing

-- Do the same For the OwnerAddress

SELECT OwnerAddress
FROM nashville_housing


WITH addr AS (
  SELECT
    OwnerAddress,
    instr(OwnerAddress, ',') AS p1,
    instr(substr(OwnerAddress, instr(OwnerAddress, ',') + 1), ',') AS p2
  FROM nashville_housing
)
SELECT
  OwnerAddress,
  TRIM(
    CASE WHEN p1 > 0 THEN substr(OwnerAddress, 1, p1 - 1)
         ELSE OwnerAddress END
  ) AS Owner_Street,
  TRIM(
    CASE
      WHEN p1 = 0 THEN NULL
      WHEN p2 > 0 THEN substr(OwnerAddress, p1 + 1, p2 - 1)
      ELSE substr(OwnerAddress, p1 + 1)
    END
  ) AS Owner_City,
  TRIM(
    CASE
      WHEN p2 > 0 THEN substr(OwnerAddress, p1 + p2 + 1)
      ELSE NULL
    END
  ) AS Owner_State
FROM addr
LIMIT 50;


-- Add New Columns 

ALTER TABLE nashville_housing ADD COLUMN Owner_Street TEXT;
ALTER TABLE nashville_housing ADD COLUMN Owner_City TEXT;
ALTER TABLE nashville_housing ADD COLUMN Owner_State TEXT;


-- Update the table to populate the New Columns 

UPDATE nashville_housing
SET
  Owner_Street = TRIM(
    CASE WHEN instr(OwnerAddress, ',') > 0
         THEN substr(OwnerAddress, 1, instr(OwnerAddress, ',') - 1)
         ELSE OwnerAddress
    END
  ),

  Owner_City = TRIM(
    CASE
      WHEN instr(OwnerAddress, ',') = 0 THEN NULL
      WHEN instr(substr(OwnerAddress, instr(OwnerAddress, ',') + 1), ',') > 0
        THEN substr(
               OwnerAddress,
               instr(OwnerAddress, ',') + 1,
               instr(substr(OwnerAddress, instr(OwnerAddress, ',') + 1), ',') - 1
             )
      ELSE substr(OwnerAddress, instr(OwnerAddress, ',') + 1)
    END
  ),

  Owner_State = TRIM(
    CASE
      WHEN instr(substr(OwnerAddress, instr(OwnerAddress, ',') + 1), ',') > 0
        THEN substr(
               OwnerAddress,
               instr(OwnerAddress, ',') + instr(substr(OwnerAddress, instr(OwnerAddress, ',') + 1), ',') + 1
             )
      ELSE NULL
    END
  )
WHERE OwnerAddress IS NOT NULL;


-- Verify Results 

SELECT OwnerAddress, Owner_Street, Owner_City, Owner_State
FROM nashville_housing
LIMIT 50;

- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 

-- Change Y and N to Yes and No in "Solid as vacant" field 

SELECT DISTINCT (SoldAsVacant), count(SoldAsVacant)
FROM nashville_housing
GROUP by SoldAsVacant
Order by 2;


SELECT SoldAsVacant,
	CASE WHEN SoldAsVacant = 'Y' THEN 'YES'
				WHEN SoldAsVacant = 'N' THEN 'NO' 
				ELSE SoldAsVacant
				END AS Cleaned_SoldAsVacant
FROM nashville_housing;


UPDATE nashville_housing
SET SoldAsVacant = 
  CASE 
    WHEN SoldAsVacant = 'Y' THEN 'Yes'
    WHEN SoldAsVacant = 'N' THEN 'No'
    ELSE SoldAsVacant
  END;

  - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
  
-- Remove Duplicates

DELETE FROM nashville_housing
WHERE UniqueID IN (
  SELECT UniqueID FROM (
SELECT 
      UniqueID,
      ROW_NUMBER() OVER (
        PARTITION BY ParcelID, PropertyAddress, SalePrice, SaleDate, LegalReference
        ORDER BY UniqueID
      ) AS row_num
    FROM nashville_housing
	)
WHERE row_num > 1
);

  - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
  
-- Delete Unused Columns 

SELECT*
FROM nashville_housing;


ALTER TABLE nashville_housing DROP COLUMN OwnerAddress;
ALTER TABLE nashville_housing DROP COLUMN TaxDistrict;
ALTER TABLE nashville_housing DROP COLUMN PropertyAddress; 

ALTER TABLE nashville_housing DROP COLUMN SaleDate;





