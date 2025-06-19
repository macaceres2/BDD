# Entrega 3: Trabajo Local 

Para trabajar localmente con la base de datos del servidor, puedes seguir estos pasos:

1. Ingresar a PSQL por consola:
    ```bash
    psql postgres
    ```

2. Crea el usuario _booked_
    ```sql
    CREATE ROLE booked WITH PASSWORD 'bdd2025-1'
    ```

3. Ejecutar la base de datos para su creaciónde forma local, puede ser dentro de la consola de Postgresql
    ```sql
    \i /ruta/al/archivo/de/la/bdd/E3.sql
    ```

    ó por consola

    ```bash
    psql -f E3.sql -U booked -d postgres
    ```    


4. Finalmente puedes ingresar a la base de datos de la siguiente forma
    ```bash
    psql -d e3
    ```    

    ó dentro de Postgres

    ```psql
    \c e3
    ```    

5. Si se cumplieron todos los pasos con éxito, deberías visualizar lo siguiente en la consola de Postgresql

    ```psql
    e3=# 
    ```  

    Puedes probar la siguiente consulta
    ```psql
    SELECT * FROM persona LIMIT 1;
    ```  
    Deberías obtener el siguiente resultado

    | correo                               | nombre                        | contrasena     | username              | telefono_contacto | run     | dv |
    |--------------------------------------|-------------------------------|----------------|------------------------|--------------------|---------|----|
    | Benjamínmanzanares161@viajesanma.com | Benjamín Carrion Manzanares   | xLc6IGXy6TEukhP | Benjamínmanzanares121 | +56 2 6942 5074     | 3393809 | 8  |
