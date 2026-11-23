## Задание

1. Разработать синхронное FIFO с интерфейсом AXI-Stream
2. Разработать тестбенч с проверкой Idle и Backpressure для AXI-Stream FIFO

`axis_fifo` передаёт `TDATA` через `TVALID/TREADY`. Параметр `DEPTH` задаёт
число слов. `make test` проверяет паузы, противодавление и порядок передачи.
