SET NOCOUNT ON;
GO

SELECT DB_NAME() AS database_name;

SELECT 'users' AS table_name, COUNT(*) AS row_count FROM dbo.users
UNION ALL SELECT 'drivers', COUNT(*) FROM dbo.drivers
UNION ALL SELECT 'vehicles', COUNT(*) FROM dbo.vehicles
UNION ALL SELECT 'ride_types', COUNT(*) FROM dbo.ride_types
UNION ALL SELECT 'trips', COUNT(*) FROM dbo.trips
UNION ALL SELECT 'trip_assignments', COUNT(*) FROM dbo.trip_assignments
UNION ALL SELECT 'payments', COUNT(*) FROM dbo.payments
UNION ALL SELECT 'ratings', COUNT(*) FROM dbo.ratings
UNION ALL SELECT 'notifications', COUNT(*) FROM dbo.notifications
UNION ALL SELECT 'driver_location_logs', COUNT(*) FROM dbo.driver_location_logs;

SELECT TOP (5)
    id,
    ho_ten,
    email,
    thanh_pho,
    vai_tro
FROM dbo.users
ORDER BY ngay_tao DESC;

SELECT TOP (5)
    ma_chuyen_di,
    ten_tai_xe,
    bien_so,
    dia_chi_diem_don,
    dia_chi_diem_den,
    so_tien,
    trang_thai_chuyen
FROM dbo.vw_trip_details
ORDER BY ngay_tao DESC;
GO

