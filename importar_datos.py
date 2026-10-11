import csv
import pyodbc

from datetime import datetime
from decimal import Decimal

#Conectar con SQL Server
conexion = pyodbc.connect(
    "DRIVER={ODBC Driver 18 for SQL Server};"
    "SERVER=localhost;"
    "DATABASE=IngenieriaFeatures;"
    "Trusted_Connection=yes;"
    "TrustServerCertificate=yes;"
)

cursor = conexion.cursor()

consulta = """
insert into dbo.RetailTransactions (
     InvoiceNo, StockCode, Description, Quantity,
     InvoiceDate, UnitPrice, CustomerID, Country
) 
values (?, ?, ?, ?, ?, ?, ?, ?)
"""

lote = []
tamano_lote = 2000
total = 0

try:
    with open(
        "online_retail.csv",
        "r",
        encoding="utf-8-sig",
        newline=""
    ) as archivo:
        lector = csv.DictReader(archivo)

        for fila in lector:
            invoice_no = fila["InvoiceNo"] or None
            stock_code = fila["StockCode"] or None
            description = fila["Description"] or None
            country = fila["Country"] or None

            quantity = int(fila["Quantity"])
            invoice_date = datetime.strptime(
                fila["InvoiceDate"],
                "%Y-%m-%d %H:%M:%S"
            )

            unit_price = Decimal(fila["UnitPrice"])

            customer_raw = fila["CustomerID"].strip()
            customer_id = (
                int(float(customer_raw))
                if customer_raw
                else None
            )

            lote.append((
                invoice_no,
                stock_code,
                description,
                quantity,
                invoice_date,
                unit_price,
                customer_id,
                country
            ))

            if len(lote) >= tamano_lote:
                cursor.executemany(consulta, lote)
                conexion.commit()
                total += len(lote)
                print(f"Importados {total}")
                lote.clear()

    # Insertar el ultimo lote, si quedan registros
    if lote:
        cursor.executemany(consulta, lote)
        conexion.commit()
        total += len(lote)

    print(f"Importacion finalizada: {total} registros.")

except Exception:
    conexion.rollback()
    raise

finally:
    cursor.close()
    conexion.close()