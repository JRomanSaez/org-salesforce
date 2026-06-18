// Script de consola anónima: prueba el callout de integración.
// Ejecuta:  sf apex run --file scripts/probar-callout.apex
TodoApiClient.Todo t = TodoApiClient.getTodo(1);
System.debug('Todo recibido => id=' + t.id + ', title=' + t.title + ', completed=' + t.completed);
