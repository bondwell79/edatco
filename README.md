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
                  | Comprobación de Parámetros    |
                  +-------------------------------+
                                       |
                          +------------+------------+
                          |                         |
                          V                         V
            +----------------------+        +----------------------+
            | Interfaz de Usuario  |        | Modo Automático      |
            | (Menu basado         |        | (Parametros CLI)     |
            |  en comandos)        |        +----------------------+
            +----------+-----------+                |
                       |                            V
                       V                +------------------------------+
           +-----------------------+    | Lógica Común                 |
           | Parámetros de Entrada |----| (Cargar tabla, especificaciones|
           +-----------+-----------+    |  auxiliar, ejecutar operación, |
                       |                |  exportar resultados)          |
                       V                +--------------+---------------+
         +---------------------+        |              |
         | Cargar Estructura   |        V              V
         +-----------+---------+ +------+--------------+-------+
                     |           | Cargar Registros CSV Aux.   |
                     V           +-----------------------------+
          +----------+---------------------------+
      +---| Procesar Registros (Carga,           |
      |   | Conversión, Manipulación)            |
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
      | Si ocurre algún error en cualquier fase,  |           
      | este será manejado y reportado            |
      +-------------------------------------------+

