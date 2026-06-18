/**
 * Trigger de Account. NO contiene lógica: solo delega en el handler.
 * Patrón "One Trigger Per Object": un único trigger por objeto que reparte
 * el trabajo según el evento. Facilita el mantenimiento y evita conflictos.
 */
trigger AccountTrigger on Account (before insert, before update) {
    if (Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate)) {
        AccountTriggerHandler.setNombreLongitud(Trigger.new);
    }
}
