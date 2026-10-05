USE ManufacturingQualityDB;
GO


DROP TABLE IF EXISTS dbo.Defects;
DROP TABLE IF EXISTS dbo.Downtimes;
DROP TABLE IF EXISTS dbo.ProductionLogs;
DROP TABLE IF EXISTS dbo.DefectTypes;
DROP TABLE IF EXISTS dbo.WorkOrders;
DROP TABLE IF EXISTS dbo.Shifts;
DROP TABLE IF EXISTS dbo.Machines;
DROP TABLE IF EXISTS dbo.Products;
DROP TABLE IF EXISTS dbo.Suppliers;
GO

CREATE TABLE dbo.Suppliers (
    SupplierID     INT IDENTITY(1,1) CONSTRAINT PK_Suppliers PRIMARY KEY,
    SupplierName   NVARCHAR(100) NOT NULL CONSTRAINT UQ_Suppliers_Name UNIQUE,
    Country        NVARCHAR(50)  NULL,
    QualityRating  DECIMAL(3,2)  NULL CONSTRAINT CK_Suppliers_Rating CHECK (QualityRating BETWEEN 0 AND 5)
);

CREATE TABLE dbo.Products (
    ProductID          INT IDENTITY(1,1) CONSTRAINT PK_Products PRIMARY KEY,
    ProductCode        NVARCHAR(20)  NOT NULL CONSTRAINT UQ_Products_Code UNIQUE,
    ProductName        NVARCHAR(100) NOT NULL,
    SupplierID         INT NOT NULL CONSTRAINT FK_Products_Suppliers REFERENCES dbo.Suppliers(SupplierID),
    IdealCycleTimeSec  DECIMAL(8,2)  NOT NULL CONSTRAINT CK_Products_CycleTime CHECK (IdealCycleTimeSec > 0),
    UnitCost           DECIMAL(10,2) NOT NULL CONSTRAINT CK_Products_Cost CHECK (UnitCost >= 0)
);

CREATE TABLE dbo.Machines (
    MachineID    INT IDENTITY(1,1) CONSTRAINT PK_Machines PRIMARY KEY,
    MachineName  NVARCHAR(50) NOT NULL CONSTRAINT UQ_Machines_Name UNIQUE,
    LineName     NVARCHAR(50) NOT NULL,
    InstallDate  DATE NULL,
    IsActive     BIT NOT NULL CONSTRAINT DF_Machines_IsActive DEFAULT 1
);

CREATE TABLE dbo.Shifts (
    ShiftID         INT IDENTITY(1,1) CONSTRAINT PK_Shifts PRIMARY KEY,
    ShiftName       NVARCHAR(30) NOT NULL CONSTRAINT UQ_Shifts_Name UNIQUE,
    StartTime       TIME NOT NULL,
    EndTime         TIME NOT NULL,
    PlannedMinutes  INT  NOT NULL CONSTRAINT CK_Shifts_Planned CHECK (PlannedMinutes > 0)
);

CREATE TABLE dbo.WorkOrders (
    WorkOrderID      INT IDENTITY(1,1) CONSTRAINT PK_WorkOrders PRIMARY KEY,
    ProductID        INT NOT NULL CONSTRAINT FK_WorkOrders_Products REFERENCES dbo.Products(ProductID),
    PlannedQuantity  INT NOT NULL CONSTRAINT CK_WorkOrders_Qty CHECK (PlannedQuantity > 0),
    StartDate        DATE NOT NULL,
    DueDate          DATE NOT NULL,
    Status           NVARCHAR(20) NOT NULL CONSTRAINT DF_WorkOrders_Status DEFAULT 'Planned',
    CONSTRAINT CK_WorkOrders_Status CHECK (Status IN ('Planned','InProgress','Completed','Cancelled')),
    CONSTRAINT CK_WorkOrders_Dates  CHECK (DueDate >= StartDate)
);

CREATE TABLE dbo.ProductionLogs (
    LogID          BIGINT IDENTITY(1,1) CONSTRAINT PK_ProductionLogs PRIMARY KEY,
    WorkOrderID    INT NOT NULL CONSTRAINT FK_ProductionLogs_WorkOrders REFERENCES dbo.WorkOrders(WorkOrderID),
    MachineID      INT NOT NULL CONSTRAINT FK_ProductionLogs_Machines   REFERENCES dbo.Machines(MachineID),
    ShiftID        INT NOT NULL CONSTRAINT FK_ProductionLogs_Shifts     REFERENCES dbo.Shifts(ShiftID),
    LogDate        DATE NOT NULL,
    UnitsProduced  INT NOT NULL CONSTRAINT CK_ProductionLogs_Produced CHECK (UnitsProduced >= 0),
    UnitsRejected  INT NOT NULL CONSTRAINT DF_ProductionLogs_Rejected DEFAULT 0,
    CONSTRAINT CK_ProductionLogs_Rejected CHECK (UnitsRejected >= 0 AND UnitsRejected <= UnitsProduced),
    CONSTRAINT UQ_ProductionLogs_Run UNIQUE (WorkOrderID, MachineID, ShiftID, LogDate)
);

CREATE TABLE dbo.DefectTypes (
    DefectTypeID  INT IDENTITY(1,1) CONSTRAINT PK_DefectTypes PRIMARY KEY,
    DefectName    NVARCHAR(80) NOT NULL CONSTRAINT UQ_DefectTypes_Name UNIQUE,
    Severity      NVARCHAR(10) NOT NULL CONSTRAINT CK_DefectTypes_Severity CHECK (Severity IN ('Minor','Major','Critical'))
);

CREATE TABLE dbo.Defects (
    DefectID      BIGINT IDENTITY(1,1) CONSTRAINT PK_Defects PRIMARY KEY,
    LogID         BIGINT NOT NULL CONSTRAINT FK_Defects_ProductionLogs REFERENCES dbo.ProductionLogs(LogID),
    DefectTypeID  INT    NOT NULL CONSTRAINT FK_Defects_DefectTypes    REFERENCES dbo.DefectTypes(DefectTypeID),
    Quantity      INT    NOT NULL CONSTRAINT CK_Defects_Qty CHECK (Quantity > 0)
);

CREATE TABLE dbo.Downtimes (
    DowntimeID       BIGINT IDENTITY(1,1) CONSTRAINT PK_Downtimes PRIMARY KEY,
    MachineID        INT NOT NULL CONSTRAINT FK_Downtimes_Machines REFERENCES dbo.Machines(MachineID),
    ShiftID          INT NOT NULL CONSTRAINT FK_Downtimes_Shifts   REFERENCES dbo.Shifts(ShiftID),
    StartTime        DATETIME2(0) NOT NULL,
    EndTime          DATETIME2(0) NOT NULL,
    DurationMinutes  AS DATEDIFF(MINUTE, StartTime, EndTime) PERSISTED,
    Category         NVARCHAR(30) NOT NULL,
    CONSTRAINT CK_Downtimes_Time     CHECK (EndTime > StartTime),
    CONSTRAINT CK_Downtimes_Category CHECK (Category IN ('Breakdown','Changeover','Maintenance','MaterialShortage','Other'))
);
GO