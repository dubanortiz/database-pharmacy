create tablespace datamedicamento
owner postgres
location 'c:\mibd';
create database medicamento with owner = postgres 
tablespace=datamedicamento;
\connect medicamento;
create schema general;
create schema cliente;
create user cliente password 'cliente';
create user general password 'general';
grant usage on schema cliente to cliente;
grant usage on schema general to general;
grant usage on schema general to cliente;

create table general.contacto(
     idcontacto int primary key,
     identificacion varchar(50),
     nombre varchar(50),
     apellido varchar(50),
     telefono varchar(50),
     correo varchar(50),
     fk_codigo_laboratorio int
);

create table general.laboratorio(
    idlaboratorio int primary key,
    nombre varchar(50),
    telefono varchar(50),
    direccion varchar(50),
    fax varchar(50)
);

create table general.enfermedad(
    idenfermedad  int primary key,
    nombre varchar(50)
);
create table general.familia(
    idfamilia int primary key,
    nombre_familia varchar(50),
    iva float
);


create table general.medicamento_familia(
      fk_familia int,
      fk_enfermedad int,
      fk_medicamento int,
      estado varchar(50)
);

create table general.medicamento(
    idmedicamento  int primary key,
    nombre varchar(50),
    cantidad int,
    iva float,
    precio float,
    total float
    );
create table cliente.cliente(
     id serial primary key ,
    identificacion varchar(50) unique,
     nombre varchar(50),
     apellido varchar(50),
     telefono varchar(50),
     correo varchar(50),
     estado varchar(50) check(estado='BUEN COMPORTAMIENTO' or estado='NORMAL' or estado='EN MORA')
);
create table general.pedido(
    id int primary key,
    fk_cliente int,
    valortotal float,
    fecha date,
    estado varchar(50) check(estado='DEBE' or estado='PAGADO')
);

create table general.detalle_pedido(
     iddetallepedido int primary key,
     fk_pedido int ,
     fk_medicamento int,
     valorunitario float,
     iva float,
     cantidad int,
     total float
);

create table general.cuentabancaria(
    idcuenta varchar(50) primary key ,
    fk_cliente int,
    fk_banco int,
    numero_cuenta varchar(50),
    tipo_cuenta varchar(50) check(tipo_cuenta='ahorro' or tipo_cuenta='corriente')
);
create table general.banco (
     idbanco int primary key,
     nombrebanco varchar(50)
);


create table general.credito(
   idcredito int primary key,
   fk_pedido int,
   valor_total  float,
   cantidad_cuotas int
);

create table cliente.cuota(
   codigo_detalle_prestamo int primary key,
   codigo_prestamo int,
   valor_cuota  float,
   pago boolean,
   fecha_pago date,
   fecha date
);

create table general.auditoria(
    cliente varchar(400),
    valortotal varchar(400),
    fecha varchar(400),
    estado varchar(400),
    medicamento varchar(400),
    valorunidad varchar(400),
    iva varchar(400),
    cantidad varchar(400),
    total varchar(400),
    accion varchar(50), 
    usuario varchar(50),
    fecha_modificacion date,
    tabla varchar(100)
);


ALTER TABLE general.medicamento_familia ADD PRIMARY KEY (fk_familia,fk_enfermedad,fk_medicamento);
ALTER TABLE general.contacto ADD CONSTRAINT FK FOREIGN KEY (idcontacto) REFERENCES general.laboratorio(idlaboratorio);
ALTER TABLE general.medicamento_familia ADD CONSTRAINT fk_medicamentofamilia FOREIGN KEY (fk_familia)  REFERENCES general.familia(idfamilia);
ALTER TABLE general.medicamento_familia ADD CONSTRAINT fk_medicamentoenfermedad FOREIGN KEY (fk_enfermedad) REFERENCES general.enfermedad(idenfermedad);
ALTER TABLE general.medicamento_familia ADD CONSTRAINT fk_medicamentomedicamento FOREIGN KEY (fk_medicamento) REFERENCES general.medicamento(idmedicamento);

ALTER TABLE cliente.CUENTA ADD CONSTRAINT FK_CUENTACLIENTE FOREIGN KEY (CODIGO_CLIENTE) REFERENCES cliente.CLIENTE(CODIGO_CLIENTE);
ALTER TABLE cliente.CUENTA ADD CONSTRAINT FK_CODIGOBANCO FOREIGN KEY (CODIGO_BANCO) REFERENCES cliente.BANCO(CODIGO_BANCO);
ALTER TABLE cliente.PEDIDO ADD CONSTRAINT FK_PEDIDOCLIENTE FOREIGN KEY (CODIGO_CLIENTE) REFERENCES cliente.CLIENTE(CODIGO_CLIENTE);
ALTER TABLE cliente.DETALLE_PEDIDO ADD CONSTRAINT FK_DETALLEPEDIDO FOREIGN KEY (CODIGO_PEDIDO) REFERENCES cliente.PEDIDO(CODIGO_PEDIDO);
ALTER TABLE cliente.DETALLE_PEDIDO ADD CONSTRAINT FK_MEDICAMENTODETALLE FOREIGN KEY (CODIGO_MEDICAMENTO) REFERENCES general.MEDICAMENTO(CODIGO_MEDICAMENTO);


create or replace function calculo_total_pedido() returns trigger as $pedido$
declare
begin
   update general.pedido set valortotal=(SELECT SUM(dt.total) FROM general.detalle_pedido dt where dt.fk_pedido=new.fk_pedido) where id=new.fk_pedido;
return new;
end;
$pedido$ language plpgsql;


create or replace function calculo_detalle_pedido() returns trigger as $detalle$
declare 
    valor_medicamento float;
    iva_medicamento float;
begin
 select m.precio,f.iva into valor_medicamento,iva_medicamento from general.medicamento m
 inner join general.medicamento_familia mf on(mf.fk_medicamento=m.idmedicamento) 
 inner join general.familia f on(f.idfamilia=mf.fk_familia)   
 where m.idmedicamento=new.fk_medicamento limit 1;
   new.valorunitario=valor_medicamento;
   new.iva:=iva_medicamento;
   new.total:= ((valor_medicamento*iva_medicamento)+ valor_medicamento)*new.cantidad;
return new;
end;
$detalle$ language plpgsql;


create or replace function auditoria() returns trigger as $$
declare 
begin
if(tg_op = 'DELETE')  then
if (TG_TABLE_NAME = 'detalle_pedido') then
insert into  general.auditoria(tabla,fecha, valortotal, cliente, estado, medicamento, valorunidad, iva, cantidad, total, accion, usuario,fecha_modificacion) 
values(TG_TABLE_NAME,NULL,NULL,NULL,NULL,OLD.fk_medicamento, old.valorunitario, old.iva, old.cantidad,old.total, 'elimino',session_user, now());
else
insert into  general.auditoria(tabla,fecha, valortotal, cliente, estado, medicamento, valorunidad, iva, cantidad, total, accion, usuario,fecha_modificacion) 
values(TG_TABLE_NAME,old.fecha,old.valortotal,old.fk_cliente,old.estado,null, null, null, null,null, 'elimino',session_user, now());
end if;
return old;
elsif(tg_op = 'INSERT')then 
if (TG_TABLE_NAME = 'detalle_pedido') then
insert into  general.auditoria(tabla,fecha, valortotal, cliente, estado, medicamento, valorunidad, iva, cantidad, total, accion, usuario,fecha_modificacion) 
values(TG_TABLE_NAME,NULL,NULL,NULL,NULL,new.fk_medicamento, new.valorunitario, new.iva, new.cantidad,new.total, 'inserto',session_user, now());
else
insert into  general.auditoria(tabla,fecha, valortotal, cliente, estado, medicamento, valorunidad, iva, cantidad, total, accion, usuario,fecha_modificacion) 
values(TG_TABLE_NAME,new.fecha,new.valortotal,new.fk_cliente,new.estado,null, null, null, null,null, 'inserto',session_user, now());
end if;
return new;

elsif(tg_op = 'UPDATE') then 
if (TG_TABLE_NAME = 'detalle_pedido') then

insert into  general.auditoria(tabla,fecha, valortotal, cliente, estado, medicamento, valorunidad, iva, cantidad, total, accion, usuario,fecha_modificacion) 
values(TG_TABLE_NAME,NULL,NULL,NULL,NULL,new.fk_medicamento||'-'||old.fk_medicamento, new.valorunitario||'-'||old.valorunitario, new.iva||'-'||old.iva, new.cantidad ||'-'||old.cantidad,new.total, 'inserto',session_user, now());
else
insert into  general.auditoria(tabla,fecha, valortotal, cliente, estado, medicamento, valorunidad, iva, cantidad, total, accion, usuario,fecha_modificacion) 
values(TG_TABLE_NAME,new.fecha||'-'||old.fecha,new.valortotal||'-'||old.valortotal,new.fk_cliente||'-'||old.fk_cliente,new.estado||'-'||old.estado,null, null, null, null,null, 'inserto',session_user, now());
end if;
return new;
end if;
return null;
end;
$$ language plpgsql;


create trigger auditoria_pedido after insert or delete  or update on general.pedido for each row execute procedure auditoria('pedido');
create trigger auditoria_detallepedido after insert or delete  or update on general.detalle_pedido for each row execute procedure auditoria();



create trigger tr_detalle_pedido before insert on general.detalle_pedido for each row execute procedure calculo_detalle_pedido();


create trigger tr_pedido after insert on general.detalle_pedido for each row execute procedure  calculo_total_pedido();


copy cliente.CLIENTE (identificacion,nombre,apellido,telefono,correo,estado) from ‘D:/Documents/CLIENTESPARCIAL.csv’ delimiter ‘;’ csv header;

insert into general.BANCO VALUES(9,'BANCOLOMBIA');
insert into general.BANCO VALUES(2,'BANCO DE BOGOTA');
insert into general.BANCO VALUES(7,'DAVIVIENDAD');
insert into general.BANCO VALUES(4,'BANCO AGRARIO');
insert into general.BANCO VALUES(5,'BANCO DE OCCIDENTE');
insert into general.BANCO VALUES(6,'BANCO POPULAR');
insert into general.BANCO VALUES(8,'BANCO AV VILLAS');
insert into general.BANCO VALUES(2,'BBVA');
insert into general.BANCO VALUES(1,'BANCO CAJA SOCIAL');
insert into general.BANCO VALUES(10,'BANCO SANDOVAL');
insert into general.cuentabancaria values(1,1,1,'92iejsa9','ahorro');
insert into general.cuentabancaria values(2,2,2,'29eoamsw','corriente');
insert into general.cuentabancaria values(3,3,1,'9293sisw','ahorro');
insert into general.cuentabancaria values(4,4,3,'0392slsl','ahorro');
insert into general.cuentabancaria values(5,5,5,'28skxmez','corriente');
insert into general.cuentabancaria values(6,6,5,'4oelswm3','ahorro');
insert into general.cuentabancaria values(7,7,1,'3isp65jd','corriente');
insert into general.cuentabancaria values(8,8,2,'1s5ewe32','ahorro');
insert into general.cuentabancaria values(9,9,2,'384ksald','ahorro');
insert into general.cuentabancaria values(10,10,2,'384dal32','ahorro');
insert into general.PEDIDO values(1,1,0,'2019-02-03','DEBE');
insert into general.PEDIDO values(2,2,0,'2019-03-03','DEBE');
insert into general.PEDIDO values(3,3,0,'2019-04-03','DEBE');
insert into general.PEDIDO values(4,5,0,'2019-05-03','DEBE');
insert into general.PEDIDO values(5,5,0,'2019-06-03','DEBE');
insert into general.PEDIDO values(6,6,0,'2019-07-03','DEBE');
insert into general.PEDIDO values(7,1,0,'2019-08-03','DEBE');
insert into general.PEDIDO values(8,2,0,'2019-09-03','DEBE');
insert into general.PEDIDO values(9,3,0,'2019-10-03','DEBE');
insert into general.PEDIDO values(10,4,0,'2019-11-03','DEBE');
insert into general.PEDIDO values(11,5,0,'2019-11-03','DEBE');
insert into general.PEDIDO values(12,4,0,'2019-11-03','DEBE');
insert into general.LABORATORIO values(1,'MI LABORATORIO','314141','CALLE','02201');
insert into general.LABORATORIO values(2,'FAMI','3141321','CALLE2123','02201');
insert into general.LABORATORIO values(3,'LASANTE','314141','CALLE','02201');
insert into general.LABORATORIO values(4,'MK','314141','CALLE','02201');
insert into general.LABORATORIO values(5,'LABOY','314141','CALLE','02201');
insert into general.LABORATORIO values(6,'FACTORY','314141','CALLE','02201');
insert into general.LABORATORIO values(7,'LABMAYE','314141','CALLE','02211');
insert into general.LABORATORIO values(8,'MODICAK','314141','CALLE','02221');
insert into general.LABORATORIO values(9,'FLOLAB','314141','CALLE','02241');
insert into general.LABORATORIO values(10,'MALLAB','314141','CALLE','0223');
insert into general.CONTACTO values(1,'1117834023','MARIA','ROJAS','4345784','12345678',1);
insert into general.CONTACTO values(2,'26354937','CARLOS','CALLE','4582148','12345678',2);
insert into general.CONTACTO values(3,'45768134','FEDERICO','TORRES','4358967','12345678',3);
insert into general.CONTACTO values(4,'1116789234','MAURICIO','FUENTES','0914578','12345678',4);
insert into general.CONTACTO values(5,'1876034','LEON','VALENCIA','4367852','12345678',5);
insert into general.CONTACTO values(6,'45274812','LAURA','TRIANA','45781234','12345678',6);
insert into general.CONTACTO values(7,'1876345','JUAN','MATA','4367845','12345678',7);
insert into general.CONTACTO values(8,'26634918','PEDRO','PEREZ','4375419','12345678',8);
insert into general.CONTACTO values(9,'26834012','ANGIE','POLO','0578943','12345678',9);
insert into general.CONTACTO values(10,'1657023','TITO','PAEZ','1234567','12345678',10);
insert into general.FAMILIA values(1,'ANALGESICO',0);
insert into general.FAMILIA values(2,'ANTIACIDOS',0.08);
insert into general.FAMILIA values(3,'ANTIALERGICOS',0);
insert into general.FAMILIA values(4,'ANTIINFECCIOSOS',0);
insert into general.FAMILIA values(5,'ANTIBIOTICO',0.07);
insert into general.FAMILIA values(6,'ANTIFEAS',0.19);
insert into general.FAMILIA values(7,'ANTIDIARREICO',0.19);
insert into general.FAMILIA values(8,'ANTIPROFESORESDEBD',0.19);
insert into general.FAMILIA values(9,'ANTIINFLAMATORIAS',0.19);
insert into general.FAMILIA values(10,'MUCOLITICOS',0.19);

insert into general.ENFERMEDAD values(1,'MIGRAÑA');
insert into general.ENFERMEDAD values(2,'GRIPA');
insert into general.ENFERMEDAD values(3,'DIARREA');
insert into general.ENFERMEDAD values(4,'ESTUDIAR BD');
insert into general.ENFERMEDAD values(5,'FIEBRE');
insert into general.ENFERMEDAD values(6,'CANCER');
insert into general.ENFERMEDAD values(7,'VIH');
insert into general.ENFERMEDAD values(9,'CANDIASIS');
insert into general.ENFERMEDAD values(10,'DIABETES');

insert into general.MEDICAMENTO values(1,'ACETAMINOFEN',500,0.08,3000,0);
insert into general.MEDICAMENTO values(2,'IBUPROFENO',500,0.08,2000,0);
insert into general.MEDICAMENTO values(3,'DOLEX',500,0.08,1000,0);
insert into general.MEDICAMENTO values(4,'NOXPIRON',500,0.08,3000,0);
insert into general.MEDICAMENTO values(5,'PASTILLAS PARA EL PARCIAL',500,0.08,1000,0);
insert into general.MEDICAMENTO values(6,'POSTGRESUCOL',500,0.08,4000,0);
insert into general.MEDICAMENTO values(7,'MYSQLXD',500,0.08,2000,0);
insert into general.MEDICAMENTO values(8,'CLOTRIMAZOL',500,0.08,4000,0);
insert into general.MEDICAMENTO values(9,'DOXICILINA',500,0.08,2000,0);
insert into general.MEDICAMENTO values(10,'AMOXICILINA',500,0.08,1000,0);


insert into general.medicamento_familia values(1,1,1,'activo');
insert into general.medicamento_familia values(1,2,2,'activo');
insert into general.medicamento_familia values(2,3,3,'activo');
insert into general.medicamento_familia values(2,4,4,'activo');
insert into general.medicamento_familia values(3,5,5,'activo');
insert into general.medicamento_familia values(3,2,6,'activo');
insert into general.medicamento_familia values(4,3,7,'activo');
insert into general.medicamento_familia values(5,1,8,'activo');
insert into general.medicamento_familia values(6,2,9,'activo');
insert into general.medicamento_familia values(7,6,10,'activo');



insert into  general.DETALLE_PEDIDO values(1,1,1,0,3,2,0);
insert into general.DETALLE_PEDIDO values(2,1,2,0,2,3,0);
insert into general.DETALLE_PEDIDO values(3,1,3,0,3,1,0);
insert into general.DETALLE_PEDIDO values(4,2,1,0,1,2,0);

select *from general.pedido;
 select *from general.detalle_pedido;

select CONCAT(cli.nombre,' ',cli.apellido) AS "NOMBRE CLIENTE",m.nombre AS "MEDICAMENTO",dp.CANTIDAD AS "CANTIDAD",dp.TOTAL AS "VALOR TOTAL" 
from general.pedido p 
 inner join general.detalle_pedido dp on(dp.fk_pedido=p.id) 
 inner join general.medicamento m on(m.idmedicamento=dp.fk_medicamento)
 inner join cliente.cliente cli on(p.fk_cliente=cli.id) WHERE p.id=1;


SELECT m.idmedicamento,m.nombre,(CASE WHEN (select count(*) from general.medicamento_familia where medicamento_familia.fk_familia= (select  fk_familia from 
general.medicamento inner join general.medicamento_familia on medicamento_familia.fk_medicamento = medicamento.idmedicamento where medicamento.idmedicamento=m.idmedicamento))>1 then 'SI TIENE' ELSE 'NO TIENE' END) AS "MEDICAMENTO EQUIVALENTE" FROM general.medicamento m;


select c.id,c.nombre||' '||c.apellido  as "CLIENTE CON MAS PEDIDOS",count(*) AS "CANTIDAD DE PEDIDO"  from cliente.cliente c inner join general.pedido p on p.fk_cliente = c.id group by c.id,c.nombre,c.apellido order by "CANTIDAD DE PEDIDO" DESC LIMIT 1; 



SELECT  m.idmedicamento AS "codigo",m.nombre AS "MEDICAMENTO MENOS PEDIDO",SUM(dt.CANTIDAD) AS "CANTIDAD" FROM general.detalle_pedido dt inner join general.medicamento m on(dt.fk_medicamento=m.idmedicamento) group by m.idmedicamento,m.nombre ORDER BY "CANTIDAD" ASC LIMIT 1;

select c.id, c.nombre||' '||c.apellido as "NO HAN HECHO PEDIDO" from general.pedido p full outer join cliente.cliente c on(c.id=p.fk_cliente) where p.fk_cliente is null;

