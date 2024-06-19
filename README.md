# edatco
aplicativo para reformatear ficheros de texto plano
                             +--------------------+
                             |  EDATCO            |
                             |  Transformador de  |
                             |  Datos             |
                             +--------------------+
                                       |
                                       V
                             +------------------+
                             | Verificar Licencia|
                             +---------+--------+
                                       |
                                       V
                  +-------------------------------+
                  | Comprobaci�n de Par�metros    |
                  +-------------------------------+
                                       |
                          +------------+------------+
                          |                         |
                          V                         V
            +----------------------+        +----------------------+
            | Interfaz de Usuario  |        | Modo Autom�tico      |
            | (Menu basado         |        | (Parametros CLI)     |
            |  en comandos)        |        +----------------------+
            +----------+-----------+                |
                       |                            V
                       V                +------------------------------+
           +-----------------------+    | L�gica Com�n                 |
           | Par�metros de Entrada |----| (Cargar tabla, especificaciones|
           +-----------+-----------+    |  auxiliar, ejecutar operaci�n, |
                       |                |  exportar resultados)          |
                       V                +--------------+---------------+
         +---------------------+        |              |
         | Cargar Estructura   |        V              V
         +-----------+---------+ +------+--------------+-------+
                     |           | Cargar Registros CSV Aux.   |
                     V           +-----------------------------+
          +----------+---------------------------+
      +---| Procesar Registros (Carga,           |
      |   | Conversi�n, Manipulaci�n)            |
      |   +------------+------+------------------+
      |                |      |
      |                V      V
      |    +-------------------------+ +---------------------------+
      |    | Marcar Registros         | | Aplicar Operaciones (Sumas,|
      |    +---------+----------------+ | Agrupaciones, etc.)        |
      |              |                  +----------------------------+
      |              V
      |  +-------------------------+
      |  | Exportar a CSV o SQL    |
      |  +---------+---------------+
      |              |
      |              V
      |  +-------------------------+
      |  | Fin del Proceso         |
      |  +-------------------------+
      |
      +-------------------------------------------+
                        EXCEPCIONES                |
      +-------------------------------------------+
      | Si ocurre alg�n error en cualquier fase,  |           
      | este ser� manejado y reportado            |
      +-------------------------------------------+

