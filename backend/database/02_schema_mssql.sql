SET NOCOUNT ON;
SET QUOTED_IDENTIFIER ON;
GO

IF DB_NAME() IN (N'master', N'model', N'msdb', N'tempdb')
BEGIN
    THROW 50001, 'Run this schema script inside RideApp_Nam, RideApp_Nam_Replica, RideApp_Bac, or RideApp_Bac_Replica.', 1;
END;
GO

IF OBJECT_ID(N'dbo.users', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.users (
        id UNIQUEIDENTIFIER NOT NULL CONSTRAINT DF_users_id DEFAULT NEWID(),
        ho_ten NVARCHAR(100) NOT NULL,
        email NVARCHAR(150) NOT NULL,
        mat_khau NVARCHAR(255) NOT NULL,
        so_dien_thoai VARCHAR(15) NULL,
        thanh_pho VARCHAR(10) NOT NULL,
        vai_tro VARCHAR(10) NOT NULL CONSTRAINT DF_users_vai_tro DEFAULT 'user',
        ngay_tao DATETIME2(0) NOT NULL CONSTRAINT DF_users_ngay_tao DEFAULT SYSDATETIME(),
        CONSTRAINT PK_users PRIMARY KEY (id),
        CONSTRAINT UQ_users_email UNIQUE (email),
        CONSTRAINT CK_users_thanh_pho CHECK (thanh_pho IN ('HCM', 'HN')),
        CONSTRAINT CK_users_vai_tro CHECK (vai_tro IN ('user', 'driver'))
    );
END;
GO

IF OBJECT_ID(N'dbo.ride_types', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.ride_types (
        id VARCHAR(10) NOT NULL,
        ten_loai NVARCHAR(50) NOT NULL,
        icon_name VARCHAR(50) NULL,
        gia_co_ban INT NOT NULL,
        gia_moi_km INT NOT NULL,
        mo_ta NVARCHAR(200) NULL,
        suc_chua SMALLINT NULL,
        dang_hoat_dong BIT NOT NULL CONSTRAINT DF_ride_types_dang_hoat_dong DEFAULT 1,
        CONSTRAINT PK_ride_types PRIMARY KEY (id),
        CONSTRAINT CK_ride_types_id CHECK (id IN ('bike', 'car4', 'car7')),
        CONSTRAINT CK_ride_types_gia CHECK (gia_co_ban >= 0 AND gia_moi_km >= 0)
    );
END;
GO

IF OBJECT_ID(N'dbo.drivers', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.drivers (
        id UNIQUEIDENTIFIER NOT NULL CONSTRAINT DF_drivers_id DEFAULT NEWID(),
        ma_user UNIQUEIDENTIFIER NOT NULL,
        ho_ten NVARCHAR(100) NULL,
        so_dien_thoai VARCHAR(15) NULL,
        vi_do_hien_tai DECIMAL(10,8) NULL,
        kinh_do_hien_tai DECIMAL(11,8) NULL,
        thanh_pho VARCHAR(10) NOT NULL,
        is_available BIT NOT NULL CONSTRAINT DF_drivers_is_available DEFAULT 0,
        tong_so_chuyen INT NOT NULL CONSTRAINT DF_drivers_tong_so_chuyen DEFAULT 0,
        ngay_tao DATETIME2(0) NOT NULL CONSTRAINT DF_drivers_ngay_tao DEFAULT SYSDATETIME(),
        CONSTRAINT PK_drivers PRIMARY KEY (id),
        CONSTRAINT UQ_drivers_ma_user UNIQUE (ma_user),
        CONSTRAINT FK_drivers_users FOREIGN KEY (ma_user) REFERENCES dbo.users(id),
        CONSTRAINT CK_drivers_thanh_pho CHECK (thanh_pho IN ('HCM', 'HN')),
        CONSTRAINT CK_drivers_tong_so_chuyen CHECK (tong_so_chuyen >= 0)
    );
END;
GO

IF OBJECT_ID(N'dbo.vehicles', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.vehicles (
        id UNIQUEIDENTIFIER NOT NULL CONSTRAINT DF_vehicles_id DEFAULT NEWID(),
        ma_tai_xe UNIQUEIDENTIFIER NOT NULL,
        loai_xe VARCHAR(20) NOT NULL,
        bien_so VARCHAR(20) NOT NULL,
        hang_xe NVARCHAR(50) NOT NULL,
        mau_xe NVARCHAR(30) NOT NULL,
        nam_san_xuat SMALLINT NULL,
        dang_hoat_dong BIT NOT NULL CONSTRAINT DF_vehicles_dang_hoat_dong DEFAULT 1,
        CONSTRAINT PK_vehicles PRIMARY KEY (id),
        CONSTRAINT UQ_vehicles_bien_so UNIQUE (bien_so),
        CONSTRAINT FK_vehicles_drivers FOREIGN KEY (ma_tai_xe) REFERENCES dbo.drivers(id),
        CONSTRAINT CK_vehicles_loai_xe CHECK (loai_xe IN ('xe_may', 'o_to_4_cho', 'o_to_7_cho')),
        CONSTRAINT CK_vehicles_nam_san_xuat CHECK (nam_san_xuat IS NULL OR nam_san_xuat BETWEEN 1980 AND 2100)
    );
END;
GO

IF OBJECT_ID(N'dbo.trips', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.trips (
        id UNIQUEIDENTIFIER NOT NULL CONSTRAINT DF_trips_id DEFAULT NEWID(),
        ma_nguoi_dung UNIQUEIDENTIFIER NOT NULL,
        ma_loai_dich_vu VARCHAR(10) NULL,
        vi_do_diem_don DECIMAL(10,8) NULL,
        kinh_do_diem_don DECIMAL(11,8) NULL,
        dia_chi_diem_don NVARCHAR(255) NULL,
        vi_do_diem_den DECIMAL(10,8) NULL,
        kinh_do_diem_den DECIMAL(11,8) NULL,
        dia_chi_diem_den NVARCHAR(255) NULL,
        khoang_cach_km DECIMAL(6,2) NOT NULL CONSTRAINT DF_trips_khoang_cach_km DEFAULT 1.00,
        trang_thai VARCHAR(20) NOT NULL CONSTRAINT DF_trips_trang_thai DEFAULT 'cho_xu_ly',
        thanh_pho VARCHAR(10) NOT NULL,
        ngay_tao DATETIME2(0) NOT NULL CONSTRAINT DF_trips_ngay_tao DEFAULT SYSDATETIME(),
        CONSTRAINT PK_trips PRIMARY KEY (id),
        CONSTRAINT FK_trips_users FOREIGN KEY (ma_nguoi_dung) REFERENCES dbo.users(id),
        CONSTRAINT FK_trips_ride_types FOREIGN KEY (ma_loai_dich_vu) REFERENCES dbo.ride_types(id),
        CONSTRAINT CK_trips_khoang_cach CHECK (khoang_cach_km > 0),
        CONSTRAINT CK_trips_trang_thai CHECK (trang_thai IN ('cho_xu_ly', 'dang_don', 'dang_cho', 'hoan_thanh', 'da_huy')),
        CONSTRAINT CK_trips_thanh_pho CHECK (thanh_pho IN ('HCM', 'HN'))
    );
END;
GO

IF OBJECT_ID(N'dbo.trip_assignments', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.trip_assignments (
        id UNIQUEIDENTIFIER NOT NULL CONSTRAINT DF_trip_assignments_id DEFAULT NEWID(),
        ma_chuyen_di UNIQUEIDENTIFIER NOT NULL,
        ma_tai_xe UNIQUEIDENTIFIER NOT NULL,
        trang_thai_nhan VARCHAR(20) NOT NULL CONSTRAINT DF_trip_assignments_trang_thai DEFAULT 'dang_xu_ly',
        thoi_diem_phan_cong DATETIME2(0) NOT NULL CONSTRAINT DF_trip_assignments_phan_cong DEFAULT SYSDATETIME(),
        thoi_diem_hoan_thanh DATETIME2(0) NULL,
        CONSTRAINT PK_trip_assignments PRIMARY KEY (id),
        CONSTRAINT FK_trip_assignments_trips FOREIGN KEY (ma_chuyen_di) REFERENCES dbo.trips(id),
        CONSTRAINT FK_trip_assignments_drivers FOREIGN KEY (ma_tai_xe) REFERENCES dbo.drivers(id),
        CONSTRAINT CK_trip_assignments_trang_thai CHECK (trang_thai_nhan IN ('dang_xu_ly', 'da_nhan', 'tu_choi', 'het_gio'))
    );
END;
GO

IF OBJECT_ID(N'dbo.payments', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.payments (
        id UNIQUEIDENTIFIER NOT NULL CONSTRAINT DF_payments_id DEFAULT NEWID(),
        ma_chuyen_di UNIQUEIDENTIFIER NOT NULL,
        so_tien INT NOT NULL,
        phuong_thuc VARCHAR(20) NOT NULL,
        trang_thai VARCHAR(20) NOT NULL CONSTRAINT DF_payments_trang_thai DEFAULT 'cho_thanh_toan',
        ma_giao_dich VARCHAR(100) NULL,
        thoi_diem_thanh_toan DATETIME2(0) NULL,
        CONSTRAINT PK_payments PRIMARY KEY (id),
        CONSTRAINT UQ_payments_ma_chuyen_di UNIQUE (ma_chuyen_di),
        CONSTRAINT FK_payments_trips FOREIGN KEY (ma_chuyen_di) REFERENCES dbo.trips(id),
        CONSTRAINT CK_payments_so_tien CHECK (so_tien >= 0),
        CONSTRAINT CK_payments_phuong_thuc CHECK (phuong_thuc IN ('tien_mat', 'vi_dien_tu', 'the_ngan_hang')),
        CONSTRAINT CK_payments_trang_thai CHECK (trang_thai IN ('cho_thanh_toan', 'da_thanh_toan', 'hoan_tien'))
    );
END;
GO

IF OBJECT_ID(N'dbo.ratings', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.ratings (
        id UNIQUEIDENTIFIER NOT NULL CONSTRAINT DF_ratings_id DEFAULT NEWID(),
        ma_chuyen_di UNIQUEIDENTIFIER NOT NULL,
        nguoi_danh_gia UNIQUEIDENTIFIER NOT NULL,
        loai_nguoi_danh_gia VARCHAR(10) NOT NULL,
        diem_so SMALLINT NOT NULL,
        tags_nhan_xet NVARCHAR(MAX) NULL,
        nhan_xet NVARCHAR(250) NULL,
        ngay_danh_gia DATETIME2(0) NOT NULL CONSTRAINT DF_ratings_ngay_danh_gia DEFAULT SYSDATETIME(),
        CONSTRAINT PK_ratings PRIMARY KEY (id),
        CONSTRAINT UQ_ratings_trip_type UNIQUE (ma_chuyen_di, loai_nguoi_danh_gia),
        CONSTRAINT FK_ratings_trips FOREIGN KEY (ma_chuyen_di) REFERENCES dbo.trips(id),
        CONSTRAINT FK_ratings_users FOREIGN KEY (nguoi_danh_gia) REFERENCES dbo.users(id),
        CONSTRAINT CK_ratings_loai CHECK (loai_nguoi_danh_gia IN ('user', 'driver')),
        CONSTRAINT CK_ratings_diem CHECK (diem_so BETWEEN 1 AND 5)
    );
END;
GO

IF OBJECT_ID(N'dbo.notifications', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.notifications (
        id UNIQUEIDENTIFIER NOT NULL CONSTRAINT DF_notifications_id DEFAULT NEWID(),
        nguoi_nhan UNIQUEIDENTIFIER NOT NULL,
        tieu_de NVARCHAR(100) NOT NULL,
        noi_dung NVARCHAR(MAX) NOT NULL,
        loai VARCHAR(20) NOT NULL,
        da_doc BIT NOT NULL CONSTRAINT DF_notifications_da_doc DEFAULT 0,
        da_xoa BIT NOT NULL CONSTRAINT DF_notifications_da_xoa DEFAULT 0,
        ngay_gui DATETIME2(0) NOT NULL CONSTRAINT DF_notifications_ngay_gui DEFAULT SYSDATETIME(),
        CONSTRAINT PK_notifications PRIMARY KEY (id),
        CONSTRAINT FK_notifications_users FOREIGN KEY (nguoi_nhan) REFERENCES dbo.users(id),
        CONSTRAINT CK_notifications_loai CHECK (loai IN ('dat_xe', 'huy_xe', 'hoan_thanh', 'he_thong'))
    );
END;
GO

IF OBJECT_ID(N'dbo.driver_location_logs', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.driver_location_logs (
        id BIGINT IDENTITY(1,1) NOT NULL,
        ma_tai_xe UNIQUEIDENTIFIER NOT NULL,
        ma_chuyen_di UNIQUEIDENTIFIER NULL,
        vi_do DECIMAL(10,8) NOT NULL,
        kinh_do DECIMAL(11,8) NOT NULL,
        thoi_diem DATETIME2(0) NOT NULL CONSTRAINT DF_driver_location_logs_thoi_diem DEFAULT SYSDATETIME(),
        CONSTRAINT PK_driver_location_logs PRIMARY KEY (id),
        CONSTRAINT FK_driver_location_logs_drivers FOREIGN KEY (ma_tai_xe) REFERENCES dbo.drivers(id),
        CONSTRAINT FK_driver_location_logs_trips FOREIGN KEY (ma_chuyen_di) REFERENCES dbo.trips(id)
    );
END;
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_users_thanh_pho' AND object_id = OBJECT_ID(N'dbo.users'))
    CREATE INDEX IX_users_thanh_pho ON dbo.users(thanh_pho);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_drivers_city_available' AND object_id = OBJECT_ID(N'dbo.drivers'))
    CREATE INDEX IX_drivers_city_available ON dbo.drivers(thanh_pho, is_available) INCLUDE (vi_do_hien_tai, kinh_do_hien_tai);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_trips_user_created' AND object_id = OBJECT_ID(N'dbo.trips'))
    CREATE INDEX IX_trips_user_created ON dbo.trips(ma_nguoi_dung, ngay_tao DESC);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_trips_city_status' AND object_id = OBJECT_ID(N'dbo.trips'))
    CREATE INDEX IX_trips_city_status ON dbo.trips(thanh_pho, trang_thai);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_trip_assignments_trip' AND object_id = OBJECT_ID(N'dbo.trip_assignments'))
    CREATE INDEX IX_trip_assignments_trip ON dbo.trip_assignments(ma_chuyen_di, trang_thai_nhan);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_trip_assignments_driver' AND object_id = OBJECT_ID(N'dbo.trip_assignments'))
    CREATE INDEX IX_trip_assignments_driver ON dbo.trip_assignments(ma_tai_xe, thoi_diem_phan_cong DESC);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_notifications_user_read' AND object_id = OBJECT_ID(N'dbo.notifications'))
    CREATE INDEX IX_notifications_user_read ON dbo.notifications(nguoi_nhan, da_doc, ngay_gui DESC);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_location_driver_time' AND object_id = OBJECT_ID(N'dbo.driver_location_logs'))
    CREATE INDEX IX_location_driver_time ON dbo.driver_location_logs(ma_tai_xe, thoi_diem DESC);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_location_trip_time' AND object_id = OBJECT_ID(N'dbo.driver_location_logs'))
    CREATE INDEX IX_location_trip_time ON dbo.driver_location_logs(ma_chuyen_di, thoi_diem DESC) WHERE ma_chuyen_di IS NOT NULL;
GO

MERGE dbo.ride_types AS target
USING (VALUES
    ('bike', N'Xe máy', 'two_wheeler', 12000, 4000, N'Nhanh, tiện cho 1 người', 1, CAST(1 AS BIT)),
    ('car4', N'Ô tô 4 chỗ', 'directions_car', 25000, 11000, N'Phù hợp 1-3 người', 3, CAST(1 AS BIT)),
    ('car7', N'Ô tô 7 chỗ', 'airport_shuttle', 35000, 15000, N'Gia đình hoặc nhóm bạn', 6, CAST(1 AS BIT))
) AS source (id, ten_loai, icon_name, gia_co_ban, gia_moi_km, mo_ta, suc_chua, dang_hoat_dong)
ON target.id = source.id
WHEN MATCHED THEN
    UPDATE SET
        ten_loai = source.ten_loai,
        icon_name = source.icon_name,
        gia_co_ban = source.gia_co_ban,
        gia_moi_km = source.gia_moi_km,
        mo_ta = source.mo_ta,
        suc_chua = source.suc_chua,
        dang_hoat_dong = source.dang_hoat_dong
WHEN NOT MATCHED THEN
    INSERT (id, ten_loai, icon_name, gia_co_ban, gia_moi_km, mo_ta, suc_chua, dang_hoat_dong)
    VALUES (source.id, source.ten_loai, source.icon_name, source.gia_co_ban, source.gia_moi_km, source.mo_ta, source.suc_chua, source.dang_hoat_dong);
GO

CREATE OR ALTER VIEW dbo.vw_driver_rating_summary
AS
SELECT
    d.id AS ma_tai_xe,
    CAST(AVG(CAST(r.diem_so AS DECIMAL(4,2))) AS DECIMAL(4,2)) AS diem_trung_binh,
    COUNT(r.id) AS so_luot_danh_gia
FROM dbo.drivers AS d
LEFT JOIN dbo.trip_assignments AS ta
    ON ta.ma_tai_xe = d.id
LEFT JOIN dbo.ratings AS r
    ON r.ma_chuyen_di = ta.ma_chuyen_di
    AND r.loai_nguoi_danh_gia = 'user'
GROUP BY d.id;
GO

CREATE OR ALTER VIEW dbo.vw_trip_details
AS
SELECT
    t.id AS ma_chuyen_di,
    t.ma_nguoi_dung,
    t.ma_loai_dich_vu,
    rt.ten_loai AS ten_loai_dich_vu,
    t.dia_chi_diem_don,
    t.dia_chi_diem_den,
    t.vi_do_diem_don,
    t.kinh_do_diem_don,
    t.vi_do_diem_den,
    t.kinh_do_diem_den,
    t.khoang_cach_km,
    t.trang_thai AS trang_thai_chuyen,
    t.thanh_pho,
    ta.ma_tai_xe,
    d.ho_ten AS ten_tai_xe,
    d.so_dien_thoai AS sdt_tai_xe,
    drs.diem_trung_binh AS diem_danh_gia_tai_xe,
    v.bien_so,
    v.hang_xe,
    v.mau_xe,
    v.loai_xe,
    p.so_tien,
    p.phuong_thuc,
    p.trang_thai AS trang_thai_thanh_toan,
    t.ngay_tao
FROM dbo.trips AS t
LEFT JOIN dbo.ride_types AS rt
    ON rt.id = t.ma_loai_dich_vu
OUTER APPLY (
    SELECT TOP (1)
        x.ma_tai_xe,
        x.trang_thai_nhan,
        x.thoi_diem_phan_cong
    FROM dbo.trip_assignments AS x
    WHERE x.ma_chuyen_di = t.id
    ORDER BY
        CASE WHEN x.trang_thai_nhan = 'da_nhan' THEN 0 ELSE 1 END,
        x.thoi_diem_phan_cong DESC
) AS ta
LEFT JOIN dbo.drivers AS d
    ON d.id = ta.ma_tai_xe
LEFT JOIN dbo.vehicles AS v
    ON v.ma_tai_xe = d.id
    AND v.dang_hoat_dong = 1
LEFT JOIN dbo.payments AS p
    ON p.ma_chuyen_di = t.id
LEFT JOIN dbo.vw_driver_rating_summary AS drs
    ON drs.ma_tai_xe = d.id;
GO

