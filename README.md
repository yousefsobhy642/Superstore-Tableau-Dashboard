# Superstore-Tableau-Dashboard
تصميم قاعدة بيانات علائقية (5NF) باستخدام SQL لتحليل المبيعات، متصلة بلوحة تحكم تفاعلية تعرض مؤشرات (KPIs) الأرباح وصافي المبيعات وتأثير الفئات (Furniture, Technology)، مما يسهل على الإدارة توجيه استراتيجيات المبيعات.



erDiagram
    Fact_Sales {
        int Row_ID PK
        int Order_ID 
        int Customer_ID FK
        int Product_ID FK
        int Location_ID FK
        int Ship_Mode_ID FK
        int Order_Date_ID FK
        int Ship_Date_ID FK
        float Sales
        float Profit
        int Quantity
        float Discount
    }
    
    Dim_Customer {
        int Customer_ID PK
        string Customer_Name
        string Segment
    }
    
    Dim_Product {
        int Product_ID PK
        string Product_Name
        string Category
        string Sub_Category
    }
    
    Dim_Location {
        int Location_ID PK
        string Region
        string City
        string State
    }
    
    Dim_Date {
        int Date_ID PK
        date Full_Date
        int Year
        int Quarter
        string Month_Name
    }
    
    Dim_ShipMode {
        int Ship_Mode_ID PK
        string Ship_Mode
    }

    Dim_Customer ||--o{ Fact_Sales : "1 to Many"
    Dim_Product ||--o{ Fact_Sales : "1 to Many"
    Dim_Location ||--o{ Fact_Sales : "1 to Many"
    Dim_ShipMode ||--o{ Fact_Sales : "1 to Many"
    Dim_Date ||--o{ Fact_Sales : "Order Date"
    Dim_Date ||--o{ Fact_Sales : "Ship Date"
