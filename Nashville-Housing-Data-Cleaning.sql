/*

Data Cleaning using SQL Queries

Skills used in this project: Joins, Substrings, Parsename, Partitions, CTEs, etc.

*/

SELECT *
FROM PortfolioProject.dbo.nashvillehousing;


--Standardize Date Format

SELECT SaleDate, CONVERT(Date,SaleDate)
FROM PortfolioProject.dbo.nashvillehousing;

UPDATE nashvillehousing
SET SaleDate = CONVERT(Date,SaleDate);

ALTER TABLE nashvillehousing
ADD SaleDateConverted Date;

UPDATE nashvillehousing
SET SaleDateConverted = CONVERT(Date,SaleDate);

SELECT SaleDateConverted, CONVERT(Date,SaleDate)
FROM PortfolioProject.dbo.nashvillehousing;


--Populate Property Address Data

SELECT *
FROM PortfolioProject.dbo.nashvillehousing
--WHERE PropertyAddress IS NULL
ORDER BY ParcelID
--Notice that when the ParcelID is the same, the PropertyAddress are also the same


SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM PortfolioProject.dbo.nashvillehousing a
JOIN PortfolioProject.dbo.nashvillehousing b
	ON a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress IS NULL;

UPDATE a
SET PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM PortfolioProject.dbo.nashvillehousing a
JOIN PortfolioProject.dbo.nashvillehousing b
	ON a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress IS NULL;


--Breaking out Address into Individual Columns (Address, City, Date)

SELECT PropertyAddress
FROM PortfolioProject.dbo.nashvillehousing
--WHERE PropertyAddress IS NULL
--ORDER BY ParcelID

SELECT 
SUBSTRING(PropertyAddress,1,CHARINDEX(',',PropertyAddress) -1) AS Address,
SUBSTRING(PropertyAddress,CHARINDEX(',',PropertyAddress) +1, LEN(PropertyAddress)) AS Address
FROM PortfolioProject.dbo.nashvillehousing;

ALTER TABLE nashvillehousing
ADD PropertySplitAddress NVARCHAR(255);

UPDATE nashvillehousing
SET PropertySplitAddress = SUBSTRING(PropertyAddress,1,CHARINDEX(',',PropertyAddress) -1);

ALTER TABLE nashvillehousing
ADD PropertySplitCity NVARCHAR(255);

UPDATE nashvillehousing
SET PropertySplitCity = SUBSTRING(PropertyAddress,CHARINDEX(',',PropertyAddress) +1, LEN(PropertyAddress));


--Another/Easier way:

SELECT OwnerAddress
FROM PortfolioProject.dbo.nashvillehousing;

SELECT
PARSENAME(REPLACE(OwnerAddress,',','.'),3),
PARSENAME(REPLACE(OwnerAddress,',','.'),2),
PARSENAME(REPLACE(OwnerAddress,',','.'),1)
FROM PortfolioProject.dbo.nashvillehousing;

ALTER TABLE nashvillehousing
ADD OwnerSplitAddress NVARCHAR(255);

UPDATE nashvillehousing
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress,',','.'),3);

ALTER TABLE nashvillehousing
ADD OwnerSplitCity NVARCHAR(255);

UPDATE nashvillehousing
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress,',','.'),2);

ALTER TABLE nashvillehousing
ADD OwnerSplitState NVARCHAR(255);

UPDATE nashvillehousing
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress,',','.'),1);


--Change 'Y' and 'N' to 'Yes' and 'No' in SoldAsVacant column

SELECT DISTINCT(SoldAsVacant), COUNT(SoldAsVacant)
FROM PortfolioProject.dbo.nashvillehousing
GROUP BY SoldAsVacant
ORDER BY 2;

SELECT SoldAsVacant,
CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
	WHEN SoldAsVacant = 'N' THEN 'No'
	ELSE SoldAsVacant
	END
FROM PortfolioProject.dbo.nashvillehousing;

UPDATE nashvillehousing
SET SoldAsVacant = CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
	WHEN SoldAsVacant = 'N' THEN 'No'
	ELSE SoldAsVacant
	END;


--Remove Duplicates

WITH RowNumCTE AS(
SELECT *,
	ROW_NUMBER() OVER (
		PARTITION BY ParcelID,
					PropertyAddress,
					SalePrice,
					SaleDate,
					LegalReference
					ORDER BY UniqueID
					) row_num

FROM PortfolioProject.dbo.nashvillehousing
--ORDER BY ParcelID
)
DELETE
FROM RowNumCTE
WHERE row_num > 1;


--Delete Unused Columns (normally raw/original data should not be deleted)


ALTER TABLE PortfolioProject.dbo.nashvillehousing
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress;

ALTER TABLE PortfolioProject.dbo.nashvillehousing
DROP COLUMN SaleDate;

