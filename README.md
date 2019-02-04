# database-pharmacy

 La administración de una farmacia requiere poder llevar el control de los medicamentos existentes así como de los que se van sirviendo, para lo cual se pretende diseñar acorde con las siguientes especificaciones. 
En la farmacia se requiere una catalogación de todos los medicamentos existentes para lo cual se almacenaría (un código de medicamento, el nombre del medicamento, el tipo de medicamento, unidades en almacenamiento, Unidades vendidas, precio) Existen medicamentos de venta libre y otros que solo se pueden dispensar por formula médica. 
La farmacia compra cada medicamento a un laboratorio o bien a la fábrica. De esto se desea conocer el (código de laboratorio, el nombre, el teléfono, dirección, fax), así como el nombre de la persona de contacto, los medicamentos se agrupan en familias dependiendo del tipo de enfermedad a los que dichos medicamentos se aplica, de este modo si la farmacia no dispone del medicamento completo puede vender otro similar aunque de distinto laboratorio. 
La farmacia tiene algunos clientes que realizan los pagos de los pedidos a fin de cada mes, la farmacia quiere mantener las unidades de cada medicamento comprado, así como las fechas de compra. Además es necesario conocer los datos bancarios de los clientes a crédito así como las fechas de pago de las compras que realiza cada vez que le vende al cliente o factura un medicamento. 
Creación de Objetos: 
1. Crear el tablespace datamedicamento 
2. Crear la Base de medicamento en el tablespace datamedicamento 
3. Crear el esquema general con el usuario propietario postgres 
4. Crear el esquema cliente con el usuario propietario postgres 
5. Crear el usuario cliente, general 
6. Aplicar permisos de la siguiente manera: 
a. -Permisos de usar el esquema cliente al usuario cliente. 
b. -Permisos de usar el esquema general al usuario general. 
c. -Permisos de usar el esquema general al usuario cliente. 
7. Con el Usuario postgres crear el modelo de datos medicamento. 

crear las tablas según el esquema siguiente: 
• Crear la tabla cliente en el esquema cliente 
• Crear las tablas restantes en el esquema general. 

Triggers 
Realizar los siguientes triggers: 
1. Realizar un trigger que permita validar los datos de los clientes que realizan crédito; al momento de registrar el pedido, si el monto se excede de $1’000.000 y su estado bancario presenta “BUEN COMPORTAMIENTO” automáticamente se difiere a 4 cuotas de igual monto con plazos de cada 20 dias para el pago de cada una. Si el estado es “NORMAL” se difiere a 2 cuotas, y finalmente si el estado es “EN MORA” no se genera crédito. 
2. Realizar un trigger que al momento de registrar un medicamento en el pedido y este se encuentra con stock en 0, automáticamente registre el medicamento equivalente. 
3. El sistema debe calcular automáticamente el total del pedido al igual que el valor de cada uno de los medicamentos que se registra en el pedido, se debe tener en cuenta que algunos medicamentos son exentos de IVA (solo los medicamentos de tipo analgésico, antialérgicos y Antiinfecciosos). 
4. Desarrollar los triggers de auditoria para los pedidos y su detalle, se debe registrar el usuario de la bd, la tabla que se realizó la operación, la operación (Insertar, actualizar, borrar) y los valores, en caso de las actualizaciones deben quedar los valores antiguos y nuevos 

Nota: solo se debe realizar una sola taba llamada auditoria 
Manipulación de datos 
1. Ingresar mínimo 10 registros por cada una de las tablas 
2. Realizar 5 actualizaciones, en tablas que ya contienen datos con registros padres e hijos. 
3. Borrar datos (mínimo dos en toda la BD) 
4. Desde un archivo plano importar registros para la tabla de clientes. (mostrar sentencia para la operación) 
5. Se desea conocer el cliente con sus respectivos medicamentos, cantidad, valor total de un respectivo pedido. 
6. Se desea conocer los medicamentos y mostrar si tiene el medicamento equivalente. 
7. Se desea conocer cuántos pedidos se han realizado por crédito en un determinado intervalo de fechas, además de conocer el valor total. 
8. Se desea conocer los clientes que aún no han realizado algún pedido. 
9. Se desea conocer el cliente que más pedidos ha realizado. 
10. Se desea conocer el medicamento menos solicitado. 

