# Ingeniería de Features con SQL Analítico Avanzado

## Descripción

En este proyecto trabajé con el dataset Online Retail para crear variables que permitan analizar el comportamiento de los clientes mediante SQL.

El análisis incluye las métricas RFM (Recency, Frequency y Monetary), funciones de ventana y una variable de tendencia del gasto mensual.

## Dataset

Se utiliza el dataset **Online Retail**, publicado por UCI Machine Learning Repository.

Fuente: https://archive.ics.uci.edu/dataset/352/online%2Bretail.

El dataset contiene transacciones de un comercio online entre 2010 y 2011, con información sobre facturas, productos, fechas, cantidades, precios, clientes y países.

## Tecnologías utilizadas

* Microsoft SQL Server
* SQL
* Python
* Visual Studio Code

## Estructura del proyecto

* `features.sql`: consulta analítica para preparar los datos y generar las variables.
* `importar_datos.py`: script de Python utilizado para importar el CSV a SQL Server.
* `online_retail.csv`: archivo de datos utilizado para cargar las transacciones.
* `README.md`: documentación del proyecto.

## Preparación de los datos

Para el análisis se excluyen los registros sin identificador de cliente, las facturas canceladas y las operaciones con cantidades o precios no positivos.

## Variables creadas

**Recency:** cantidad de días entre la última compra del cliente y la fecha de la última transacción disponible en el dataset.

**Frequency:** cantidad de facturas distintas asociadas a cada cliente.

**Monetary:** importe total de las compras válidas, calculado a partir de la cantidad y el precio unitario.

**Trend:** diferencia entre `GastoUltimoMes` y `PromedioHistorico`. Un valor positivo indica un gasto superior al promedio histórico y uno negativo indica un gasto inferior. Si no existe un promedio histórico para comparar, la tendencia queda sin definir.


**GastoUltimoMes:** importe total de las compras del cliente durante el último mes disponible en el dataset. Si no registró compras en ese mes, el gasto se considera cero.

**PromedioHistorico:** promedio del gasto mensual del cliente en los meses anteriores al último mes disponible, considerando los meses en los que registró compras. Si no existen meses anteriores con compras, el valor queda sin definir.



## Funciones de ventana

* `LAG()`: obtiene el gasto del mes anterior registrado para cada cliente.
* `AVG() OVER()`: calcula el promedio histórico del gasto mensual.
* `MAX() OVER()`: identifica el último mes disponible en los datos.

Se utiliza `PARTITION BY CustomerID` para separar los cálculos por cliente y `ORDER BY Mes` para mantener el orden cronológico.

## Cómo reproducir el proyecto

### 1. Descargar los archivos

Clonar el repositorio y entrar en la carpeta del proyecto.

powershell
git clone https://github.com/Debk21/Ingenier-a-de-Features-con-SQL-Anal-tico-Avanzado.git
cd Ingenier-a-de-Features-con-SQL-Anal-tico-Avanzado



### 2. Obtener el dataset

Descargar Online Retail desde la fuente oficial de UCI y guardar el archivo `Online Retail.xlsx` en la carpeta del proyecto.

Convertirlo a CSV con Python:

python
import pandas as pd

df = pd.read_excel("Online Retail.xlsx")
df.to_csv("online_retail.csv", index=False)


### 3. Crear la base y la tabla

En SQL Server, crear una base de datos llamada `IngenieriaFeatures` y ejecutar el siguiente SQL:

sql
CREATE TABLE dbo.RetailTransactions (
    InvoiceNo NVARCHAR(20),
    StockCode NVARCHAR(20),
    Description NVARCHAR(255),
    Quantity INT,
    InvoiceDate DATETIME2,
    UnitPrice DECIMAL(10,2),
    CustomerID INT,
    Country NVARCHAR(100)
);


### 4. Instalar las dependencias de Python

Instalar las bibliotecas necesarias para convertir e importar los datos:

powershell
python -m pip install pandas openpyxl pyodbc


También se necesita un controlador ODBC compatible con SQL Server y una instancia de SQL Server accesible.

### 5. Importar los datos

Ejecutar el script de importación:

powershell
python importar_datos.py


El script utiliza una conexión integrada de Windows a SQL Server. Si la instancia o las credenciales son diferentes, será necesario ajustar la cadena de conexión de `importar_datos.py`.

### 6. Ejecutar el análisis

Con la base y la tabla cargadas, ejecutar:

powershell
sqlcmd -S localhost -E -C -d IngenieriaFeatures -i features.sql


Este comando corresponde a una instalación local de SQL Server con autenticación integrada de Windows. 

## Resultado

La consulta genera una fila por cliente con transacciones válidas e incluye Recency, Frequency, Monetary, el gasto del último mes disponible, el promedio histórico y Trend.

Estas variables permiten explorar patrones de compra y pueden servir como base para futuros análisis de segmentación o abandono de clientes.

