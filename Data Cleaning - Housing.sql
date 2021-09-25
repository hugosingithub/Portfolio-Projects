-----Data Cleaning-----

Select *
From [Portfolio Project]..NashvilleHousing

-----Standardize Data Format-----

Select SaleDateConverted, CONVERT(date,SaleDate)
From [Portfolio Project]..NashvilleHousing


Update NashvilleHousing
SET SaleDate = CONVERT(date, SaleDate)

ALTER TABLE	NashvilleHousing
Add SaleDateConverted Date;

Update NashvilleHousing
SET SaleDateConverted = CONVERT(date, SaleDate)

-----Populate Property Adress Data-----

--*Check if any data which have same Parcel ID (not unique) are missing address*--

Select *
From [Portfolio Project]..NashvilleHousing
--Where PropertyAddress is null
Order by ParcelID


--*update the table to fill missing address using data with same Parcel ID*--

Select a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress, b.PropertyAddress)
From [Portfolio Project]..NashvilleHousing a
Join [Portfolio Project]..NashvilleHousing b
	on a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ]
where a.PropertyAddress is null

Update a
Set PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
From [Portfolio Project]..NashvilleHousing a
Join [Portfolio Project]..NashvilleHousing b
	on a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ]
where a.PropertyAddress is null

-----Breaking out Address into Individual Columns (Address, City, State)-----

Select PropertyAddress
From [Portfolio Project]..NashvilleHousing



SELECT
--*First part of the address before ,*--
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1),
--*Second part of the address after ,*--
SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress)+1, LEN(PropertyAddress))
From [Portfolio Project]..NashvilleHousing

ALTER TABLE	NashvilleHousing
Add PropertySplitAddress Nvarchar(255);

Update NashvilleHousing
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1)

ALTER TABLE	NashvilleHousing
Add PropertySplitCity Nvarchar(255);

Update NashvilleHousing
SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress)+1, LEN(PropertyAddress))

Select *
From [Portfolio Project]..NashvilleHousing

--*Breaking OwnerAddress which has 3 parts*--

Select OwnerAddress
From [Portfolio Project]..NashvilleHousing

Select
PARSENAME(replace(OwnerAddress, ',', '.'),3),
PARSENAME(replace(OwnerAddress, ',', '.'),2),
PARSENAME(replace(OwnerAddress, ',', '.'),1)
From [Portfolio Project]..NashvilleHousing

ALTER TABLE	NashvilleHousing
Add OwnerSplitAddress Nvarchar(255);

Update NashvilleHousing
SET OwnerSplitAddress = PARSENAME(replace(OwnerAddress, ',', '.'),3)


ALTER TABLE	NashvilleHousing
Add OwnerSplitCity Nvarchar(255);

Update NashvilleHousing
SET OwnerSplitCity = PARSENAME(replace(OwnerAddress, ',', '.'),2)

ALTER TABLE	NashvilleHousing
Add OwnerSplitState Nvarchar(255);

Update NashvilleHousing
SET OwnerSplitState = PARSENAME(replace(OwnerAddress, ',', '.'),1)

Select *
From [Portfolio Project]..NashvilleHousing

-----Change Y and N to Yes and No in "Sold as Vacant field"-----

Select Distinct(SoldAsVacant), Count(SoldAsVacant)
From [Portfolio Project]..NashvilleHousing
Group by SoldAsVacant
order by 2

Select SoldAsVacant
, Case when SoldAsVacant = 'Y' THEN 'Yes'
		when SoldAsVacant = 'N' THEN 'No'
		Else SoldAsVacant
		END

Update NashvilleHousing
SET SoldAsVacant = Case when SoldAsVacant = 'Y' THEN 'Yes'
		when SoldAsVacant = 'N' THEN 'No'
		Else SoldAsVacant
		END

-----Remove Duplicates-----

WITH RowNumCTE as (
Select *, 
	ROW_NUMBER() over (
	Partition by	ParcelID,
					PropertyAddress,
					SalePrice,
					SaleDate,
					LegalReference
					ORDER BY
						UniqueID
						) row_num

From [Portfolio Project]..NashvilleHousing
)

--*Delete Operation*--
DELETE 
From RowNumCTE
where row_num>1
--Order by PropertyAddress.

Select * 
From RowNumCTE
where row_num>1
Order by PropertyAddress

-----Delete Unused Columns-----

Select *
From [Portfolio Project]..NashvilleHousing

--*Drop unused/unwanted columns*--
Alter Table [Portfolio Project]..NashvilleHousing
Drop column OwnerAddress, TaxDistrict, PropertyAddress,SaleDate
