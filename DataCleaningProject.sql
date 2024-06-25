---------------------------------------------------------------------------------------------------------------------------------------------

--- Standardizing SaleDate Format 
ALTER TABLE NashvilleHousing 
ALTER COLUMN SaleDate DATE;

---------------------------------------------------------------------------------------------------------------------------------------------

--- Fixing PropertyAddress Data: Some PropertyAddress values are inexplicably NULL - fixing using ParcelID (Address Identifier)

--- Updating Table so PropertyAddress from record with same ParcelID takes place of NULL PropertyAddress values		
UPDATE N1
SET N1.PropertyAddress = ISNULL(N1.PropertyAddress, N2.PropertyAddress)
FROM NashvilleHousing N1
	JOIN NashvilleHousing N2 
		ON N1.ParcelID = N2.ParcelID AND N1.[UniqueID ] != N2.[UniqueID ]
WHERE N1.PropertyAddress IS NULL;

-------------------------------------------------------------------------------------------------------------------------------------------

--- Splitting Addresses into Individual Columns for Address, City, State (Note- Data uses , as delimiter)


---For PropertyAddress Column (using SUBSTRING)
ALTER TABLE NashvilleHousing 
ADD PropertyStAddress VARCHAR(255),
	PropertyCity VARCHAR(255);     ---adding new seperate StAddress and City Columns

UPDATE NashvilleHousing
SET PropertyStAddress = SUBSTRING(PropertyAddress, 0, CHARINDEX(',', PropertyAddress)),
	---Substring of street address (from beginning of PropertyAddress value until first comma, not including comma)
	PropertyCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 2 , LEN(PropertyAddress ));
		---Substring of City Name (from after first comma, not including comma or space after comma, to end of Value)

ALTER TABLE NashvilleHousing
DROP COLUMN PropertyAddress;    ---Removing original PropertyAddress Column once successfully split into StAddress and City Columns


---For OwnerAddress Column (using PARSENAME)

ALTER TABLE NashvilleHousing 
ADD OwnerStAddress VARCHAR(255),
	OwnerCity VARCHAR(255),
	OwnerState VARCHAR(255);  ---adding in StAddress, City, and State columns

UPDATE NashvilleHousing
SET OwnerStAddress = PARSENAME(REPLACE(OwnerAddress, ',','.'), 3),
	OwnerCity = PARSENAME(REPLACE(OwnerAddress, ',','.'), 2),
	OwnerState = PARSENAME(REPLACE(OwnerAddress, ',','.'),1);  ---setting values for all three columns

UPDATE NashvilleHousing
SET OwnerStAddress = LTRIM(OwnerStAddress),
	OwnerCity = LTRIM(OwnerCity),
	OwnerState = LTRIM(OwnerState);    ---trimming leading spaces for these values

ALTER TABLE NashvilleHousing
DROP COLUMN OwnerAddress; ---dropping column once OwnerAddress is successfuly split up


-------------------------------------------------------------------------------------------------------------------------------------------

---Changing "Y" and "N" Values in SoldAsVacant column to "Yes" or "No" to ensure uniformity across column

UPDATE NashvilleHousing
SET SoldAsVacant = CASE When SoldAsVacant = 'Y' THEN 'YES'  ---changing Y to Yes
						When SoldAsVacant = 'N' THEN 'NO'   --- changing N to No
						ELSE SoldAsVacant					--- stays same if not Y or N
						END;


-------------------------------------------------------------------------------------------------------------------------------------------

---Removing Duplicates

DECLARE @DuplicateID TABLE(UniqueID VARCHAR(10));

INSERT INTO @DuplicateID (UniqueID)
								(SELECT MAX(N1.UniqueID)
								FROM NashvilleHousing N1 
								GROUP BY N1.ParcelID, N1.LegalReference, N1.SaleDate, N1.SalePrice 
						 --- if a record is duplicated (same ParcelID, LegalReference, SaleDate and SalePrice)
								HAVING COUNT(*) > 1);
						 --- the larger UniqueID from the duplicates is stored in @DuplicateID table

DELETE FROM NashvilleHousing
WHERE UniqueID IN (Select * FROM @DuplicateID)
--- deletes any rows where UniqueID is in previously stored duplicate ID variable table


-------------------------------------------------------------------------------------------------------------------------------------------
	
SELECT * 
FROM NashvilleHousing
ORDER BY SaleDate
--- final table after cleaning (ordered by date of sale)