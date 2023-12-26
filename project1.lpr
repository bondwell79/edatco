program EDATCO;
//  Edatco - Transformador de datos
//  Programado por Rubén Pastor Villarrubia
//
//  Este programa es software es privado y solo puede utilizarse
//  bajo los términos de la Licencia privada de usuario que obtiene
//  por su compra.
//
//  Que terminantemente prohibido copiar, modificar o utilizar cualquier parte de
//  este código sin la previa autorización de su autor.
//
//  Copyright (C) 2023  WASXALPHA SOFTWARE
//  Quedan reservados todos los derechos.

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}{$IFDEF UseCThreads}
  cthreads,
  {$ENDIF}{$ENDIF}
  Classes, dateutils,SysUtils, CustApp,crt,dos;
Const
verprogram = ' Edatco v0094 - Wasx Alpha SLP - Software 1984, 2023 - Todos los derechos reservados. ';
licencia_mes = 12;
licencia_ano = 2025;
cliente = 'LEXER PLATAFORMA LEGAL, S.L.';
type

  { TMyApplication }

  TMyApplication = class(TCustomApplication)
  protected
    procedure DoRun; override;
  public
    constructor Create(TheOwner: TComponent); override;
    destructor Destroy; override;
    procedure WriteHelp; virtual;
  end;
  
  tcampos = record
            nombre   : string;
            tipo     : string[16]; // 0 - anular  1 texto  2 numerico
            longitud : string[16]; // 0 - ilimitado
            sel      : byte;   //1 si seleccionado
            formula  : string; // [campo]texto[campo]
            nnombre  : string; // el nombre nuevo al campo de exportacion
            end;
  registro = record
            columna  : array [0..512] of string;
            tipo     : longint;
            end;

{ TMyApplication }
var
b1,b2,b3,b4    : word;
l1,l2,l3,l4,l5,l6 : longint;
comando        : string;
is_campo       : word;
operacion      : string;
xx1,xx2        : string;
excampos       : word;
fh_mes,fh_ano  : word;
//archivo origen
archivo_origen : file;
nombre_origen,nombre_destino, tabla_aux  : string;
nombre_especf  : string;
ichr,schr      : byte;
//estructura origen
to_campos : array [0..512] of tcampos;
no_campos : word;
esutf8    : boolean; // si es true convertimo utf8 a ans

//tabla trabajo
tabla                   : array of registro;
tregistros,tcolumnas    : longint;

//tabla trabajo auxiliar
tabla2                 : array of registro;
tregistros2,tcolumnas2 : longint;

bloque                 : array of char;

//mascara1
mascara1                : array of string;
tmascara1               : longint;
//mascara2
mascara2                : array of string;
tmascara2               : longint;

Function buscapos (cad,inecad: string;pos2:word) : word;
var
x1,x2,x3,x4 : longint;
begin
{poner en mayusculas todo}
{en inecad}
for x1:=1 to length(inecad) do
                              begin
                              if (ord(inecad[x1])>96) and (ord(inecad[x1])<123) then inecad[x1]:=chr(ord(inecad[x1])-32);
                              if (inecad[x1]='ñ') then inecad[x1]:='Ñ';
                              end;
{en cadena}
for x1:=1 to length(cad) do
                              begin
                              if (ord(cad[x1])>96) and (ord(cad[x1])<123) then cad[x1]:=chr(ord(cad[x1])-32);
                              if (cad[x1]='ñ') then cad[x1]:='Ñ';
                              end;

{buscar en inecad}
if pos2=0 then pos2:=1;
if pos2>length(inecad) then pos2:=1;

x3:=1;
if (inecad<>'') and (length(inecad)>=length(cad))
   then
   begin
   x1:=pos2;
        repeat;
               if x3<=length(cad) then
               if (inecad[x1]=cad[x3])
                                    then
                                     begin
                                      if x3=1 then x4:=x1;
                                      inc(x3);
                                     end
                                     else
                                      begin
                                        if x3>1 then x1:=x4;
                                        x3:=1;
                                      end;
        inc(x1);
        until (x1>length(inecad));
   end;
if (x3>length(cad)) then buscapos:=x4 else buscapos:=0; {0 = no encontrado}
end;
function ceros(cadena: string;longitud:word):string;
var
valor : string;
begin
valor:=cadena;
if (length(valor)<longitud) and (valor[1]<>'-') then  //excluir los que tienen negativo delante
repeat;
valor:='0'+valor;
until length(valor)=longitud;
result:=valor;
end;
function fnum(cadena,precision: string):string;
var
valor,entrada   : string;
sn1             : word;
nn1,nn2,pco,pce : byte;
begin
valor:='';
entrada:=cadena;
if precision='ilimitado' then precision:='0';
nn1:=0;nn2:=0;pco:=0;pce:=strtoint(precision); // if nn1=1 es negativo
if length(entrada)>0 then
begin
if entrada[1]=',' then entrada:='0'+entrada;
     for sn1:=1 to length(entrada) do
     begin
     if (pco<pce) or (pce=0) then
        begin
             if (entrada[sn1]='0') then begin valor:=valor+entrada[sn1]; if nn2=1 then inc(pco);end;
             if (entrada[sn1]='1') then begin valor:=valor+entrada[sn1]; if nn2=1 then inc(pco);end;
             if (entrada[sn1]='2') then begin valor:=valor+entrada[sn1]; if nn2=1 then inc(pco);end;
             if (entrada[sn1]='3') then begin valor:=valor+entrada[sn1]; if nn2=1 then inc(pco);end;
             if (entrada[sn1]='4') then begin valor:=valor+entrada[sn1]; if nn2=1 then inc(pco);end;
             if (entrada[sn1]='5') then begin valor:=valor+entrada[sn1]; if nn2=1 then inc(pco);end;
             if (entrada[sn1]='6') then begin valor:=valor+entrada[sn1]; if nn2=1 then inc(pco);end;
             if (entrada[sn1]='7') then begin valor:=valor+entrada[sn1]; if nn2=1 then inc(pco);end;
             if (entrada[sn1]='8') then begin valor:=valor+entrada[sn1]; if nn2=1 then inc(pco);end;
             if (entrada[sn1]='9') then begin valor:=valor+entrada[sn1]; if nn2=1 then inc(pco);end;
        end;
        if (entrada[sn1]='-') then nn1:=1;
        if (entrada[sn1]=',') and (nn2=0) then nn2:=1;
     end;
end;
if valor='' then valor:='0';
if (valor<>'0') and (nn1=1) then valor:='-'+valor;

//igualando la precisión a lo deseado
if (pco<pce) then
         begin
         repeat;
         valor:=valor+'0'; //meto tantos ceros como precision necesito
         inc(pco);
         until pco=pce;
         end;

result:=valor;
end;
function fcoma(cadena: string;posicion:word;separador:string):string; //posicion por la izquierda
var
valor,origen : string;
sn1          : word;

begin
origen:='';  //solo numeros para esta operacion

for sn1:=1 to length(cadena) do
if (cadena[sn1]='0') or (cadena[sn1]='1') or (cadena[sn1]='2') or (cadena[sn1]='3') or (cadena[sn1]='4') or (cadena[sn1]='5') or (cadena[sn1]='6')
or (cadena[sn1]='7') or (cadena[sn1]='8') or (cadena[sn1]='9') then origen:=origen+cadena[sn1];

valor:='';

if length(origen)>0 then
for sn1:=1 to length(origen) do
begin
if (origen[sn1]='0') or (origen[sn1]='1') or (origen[sn1]='2') or (origen[sn1]='3') or (origen[sn1]='4') or (origen[sn1]='5') or (origen[sn1]='6')
or (origen[sn1]='7') or (origen[sn1]='8') or (origen[sn1]='9') then valor:=valor+origen[sn1];
if length(origen)-sn1=posicion then valor:=valor+separador;
end;


if valor='' then valor:='0';


//corrección del signo menos
if length(cadena)>0 then
if (cadena[1]='-') or (cadena[length(cadena)]='-') then valor:='-'+valor;

result:=valor;
end;

function determinarsalto(fichero,parte: string):longint;
begin
assignfile(archivo_origen,fichero);
reset(archivo_origen,1);
if filesize(archivo_origen)>8000 then l3:=8000 else l3:=filesize(archivo_origen);
setlength(bloque,l3+1000);
blockread(archivo_origen,bloque[0],l3);
writeln('Determinando posición de la palabra [',parte,'] ...');writeln;
l1:=0;//posicion dentro del bloque
l2:=1;//posicion dentro de parte
l4:=0;//posicion encontrada
repeat;
if l2<length(parte) then
                   if bloque[l1]=parte[l2] then begin
                                                if l4=0 then l4:=l1;
                                                inc(l2);
                                                end else begin l4:=0; l2:=1; end;

inc(l1);
until (l1>=l3);
closefile(archivo_origen);
writeln('Posición de salto:',l4);writeln;
if l4>0 then l4:=l4-1;
determinarsalto:=l4;
end;
procedure cargar_estructura(fichero : string; xinicio:longint);
var
buffer: string;
begin
//vaciar
no_campos:=0;
for b1:=0 to 512 do begin
                    to_campos[b1].nombre:='';
                    to_campos[b1].longitud:='';
                    to_campos[b1].sel:=0;
                    to_campos[b1].tipo:='';
                    to_campos[b1].formula:='';
                    end;

assignfile(archivo_origen,fichero);
reset(archivo_origen,1);
setlength(bloque,filesize(archivo_origen)+1000);
//READLN
blockread(archivo_origen,bloque[0],filesize(archivo_origen),l3);
// quitar comillas dobles si no son relevantes - modif 30082022
l2:=1;for l1:=0 to l3 do if bloque[l1]='"' then inc(l2);
if (l3 div l2>512) and (l2>1) then
                 begin
                 writeln('Importante: Encontradas comillas dobles sin uso. Serán eliminadas automáticamente.');
                 for l1:=0 to l3 do if bloque[l1]='"' then bloque[l1]:=' ';
                 end else
                     begin
                     writeln('Importante: Encontradas comillas dobles. Van a ser respetadas en formato.');
                     end;
// fin quitar comillas dobles
l1:=xinicio; //posicion
l2:=0; //comillas texto
l3:=l3; //tamaño máximo
buffer:='';
repeat;
buffer:=buffer+bloque[l1];
if bloque[l1]='"' then inc(l2);
inc(l1);
until (l1>=l3) or ((l2 mod 2=0) and (bloque[l1]=#13)) or ((l2 mod 2=0) and (bloque[l1]=#10));
closefile(archivo_origen);
//fin readln

// convertimos formato utf 8 a ansi nuevo 29062022
if esutf8=true then buffer:=utf8decode(buffer);

//desmenuzar estructura
no_campos:=0;b1:=1;
writeln('Analizando estructura...');
writeln('Separador de columna : chr ',ichr);
writeln('Campos reconocidos:');

repeat;
//filtros de caracteres para importación
//filtro de columnas
while ((buffer[b1]=chr(ichr)) or (buffer[b1]='"')) and (b1<=length(buffer)) do
begin
if buffer[b1]=chr(ichr) then begin
                      write(inttostr(no_campos)+' - ');writeln(to_campos[no_campos].nombre);
                      to_campos[no_campos].tipo:='texto';
                      to_campos[no_campos].longitud:='ilimitado';
                      inc(no_campos);//inc(b1);
                      end;

inc(b1);
end;
//fin de filtros para importación
if b1<=length(buffer) then to_campos[no_campos].nombre:=to_campos[no_campos].nombre+buffer[b1];
inc(b1);

until b1>length(buffer);

//ultimo campo
write(inttostr(no_campos)+' - ');writeln(to_campos[no_campos].nombre);
to_campos[no_campos].tipo:='texto';
to_campos[no_campos].longitud:='ilimitado';
inc(no_campos);
//ultimo end
writeln;
writeln('Encontrados : '+inttostr(no_campos)+' Campos');
//anulacion automatica campos
for b1:=0 to no_campos-1 do
    begin
    if to_campos[b1].nombre='' then to_campos[b1].tipo:='anular';
    end;

end;

procedure cargar_registros_cvs(fichero : string;xinicio:longint);
var
buffer : string;
begin
//vaciando memoria
if length(tabla)>0 then
for l1:=0 to length(tabla)-1 do for l2:=0 to 512 do
                       begin
                       tabla[l1].columna[l2]:='';
                       tabla[l1].tipo:=0;
                       end;

assignfile(archivo_origen,fichero);
reset(archivo_origen,1);
tregistros:=0;
setlength(bloque,filesize(archivo_origen)+1000);
blockread(archivo_origen,bloque[0],filesize(archivo_origen),l3);
// quitar comillas dobles si no son relevantes - modif 30082022
l2:=1;for l1:=0 to l3 do if bloque[l1]='"' then inc(l2);
if (l3 div l2>512) and (l2>1) then
                 begin
                 writeln('Importante: Encontradas comillas dobles sin uso. Serán eliminadas automáticamente.');
                 for l1:=0 to l3 do if bloque[l1]='"' then bloque[l1]:=' ';
                 end else
                     begin
                     writeln('Importante: Encontradas comillas dobles. Van a ser respetadas en formato.');
                     end;
// fin quitar comillas dobles
closefile(archivo_origen);
l1:=xinicio; //posicion
writeln('Longitud : '+inttostr(l3));
writeln('Posicion : '+inttostr(l1));
while (l1<l3) do
  begin

  //READLN
  l2:=0; //comillas texto
  buffer:='';
  repeat;
  buffer:=buffer+bloque[l1];
  if bloque[l1]='"' then inc(l2);
  inc(l1);
  until (l1>=l3) or ((l2 mod 2=0) and (bloque[l1]=#13)) or ((l2 mod 2=0) and (bloque[l1]=#10));
  if bloque[l1]=#13 then inc(l1);//saltar el retorno
  if bloque[l1]=#10 then inc(l1);//saltar el retorno
  //fin readln

  // convertimos a ansi nuevo 29062022
  if esutf8=true then buffer:=utf8decode(buffer);

  // procesar la linea
  b1:=1;b2:=0;b3:=0;
  repeat;
  if buffer[b1]='"' then begin inc(b3); inc(b1); end; //añado incremento b1
  if buffer[b1]='"' then begin inc(b3); inc(b1); end; //¿viene vacio el campo entrecomillado?
  if b1<=length(buffer) then
     begin
     if (buffer[b1]<>chr(ichr)) or (b3 mod 2 <> 0) then
        begin
        tabla[tregistros].columna[b2]:=tabla[tregistros].columna[b2]+buffer[b1];
        inc(b1);
        end;
     if (buffer[b1]=chr(ichr)) and (b3 mod 2 = 0) then begin inc(b2);inc(b1); end;
     end;
  until b1>length(buffer);inc(b2);
  inc(tregistros);
  //fin procesar la linea

  //truncar?
  if b2<=1 then begin
                       writeln('Registro truncado: ',tregistros,' columnas: ',b2);
                       dec(tregistros);
                       end;
  // comprobaciones
  if tregistros>=length(tabla) then
                                   begin
                                   setlength(tabla,tregistros+50);
                                   writeln('Procesando [',tregistros,']');
                                   end;
  end;
writeln;
writeln('Cargados : '+inttostr(tregistros)+' registros');
writeln('Columnas : '+inttostr(b2));
writeln('Separador de columna : chr ',ichr);
tcolumnas:=b2;
end;

procedure cargar_registros_cvs_auxiliar(fichero : string);
var
buffer : string;
begin
//vaciando memoria
if length(tabla2)>0 then
for l1:=0 to length(tabla2)-1 do for l2:=0 to 512 do
                       begin
                       tabla2[l1].columna[l2]:='';
                       tabla2[l1].tipo:=0;
                       end;

assignfile(archivo_origen,fichero);
reset(archivo_origen,1);
tregistros2:=0;
setlength(bloque,filesize(archivo_origen)+1000);
blockread(archivo_origen,bloque[0],filesize(archivo_origen),l3);
// quitar comillas dobles si no son relevantes - modif 30082022
l2:=1;for l1:=0 to l3 do if bloque[l1]='"' then inc(l2);
if (l3 div l2>512) and (l2>1) then
                 begin
                 writeln('Importante: Encontradas comillas dobles sin uso. Serán eliminadas automáticamente.');
                 for l1:=0 to l3 do if bloque[l1]='"' then bloque[l1]:=' ';
                 end else
                     begin
                     writeln('Importante: Encontradas comillas dobles. Van a ser respetadas en formato.');
                     end;
// fin quitar comillas dobles
closefile(archivo_origen);
l1:=0; //posicion
writeln('Longitud : '+inttostr(l3));
while (l1<l3) do
  begin
  //READLN
  l2:=0; //comillas texto
  buffer:='';
  repeat;
  buffer:=buffer+bloque[l1];
  if bloque[l1]='"' then inc(l2);
  inc(l1);
  until (l1=l3) or ((l2 mod 2=0) and (bloque[l1]=#13)) or ((l2 mod 2=0) and (bloque[l1]=#10));
  if bloque[l1]=#13 then inc(l1);//saltar el retorno
  if bloque[l1]=#10 then inc(l1);//saltar el retorno
  //fin readln

  // convertimos a ansi 29062022
  if esutf8=true then buffer:=utf8decode(buffer);

  b1:=1;b2:=0;b3:=0;
  repeat;
  if buffer[b1]='"' then begin inc(b3); inc(b1); end; // incremento en b1
  if buffer[b1]='"' then begin inc(b3); inc(b1); end; //¿viene vacio el campo entrecomillado?
  if b1<=length(buffer) then
  begin
       if (buffer[b1]<>chr(ichr)) or (b3 mod 2 <> 0) then
          begin
          tabla2[tregistros2].columna[b2]:=tabla2[tregistros2].columna[b2]+buffer[b1];
          inc(b1);
          end;
       if (buffer[b1]=chr(ichr)) and (b3 mod 2 = 0) then begin inc(b2);inc(b1); end;

  end;
  until b1>length(buffer);inc(b2);
  inc(tregistros2);
  if tregistros2>=length(tabla2) then begin
                                      setlength(tabla2,tregistros2+4000);
                                      writeln('Procesando [',tregistros2,']');
                                      end;
  end;
writeln;
writeln('Cargados : '+inttostr(tregistros2)+' registros');
writeln('Columnas : '+inttostr(b2));
writeln('Separador de columna : chr ',ichr);
tcolumnas2:=b2;
end;

function truncada(cadena:string):string;
var
trc : word;
res : string;
begin
trc:=0;res:='';
if length(cadena)>0 then
begin
repeat;
if (cadena[trc]<>#13) and (cadena[trc]<>#10) and (cadena[trc]<>'"') then res:=res+cadena[trc];
inc(trc);
until (trc>32) or (trc>length(cadena));
if trc<length(cadena) then res:=res+' .. ('+inttostr(length(cadena))+')';
end;
result:=res;
end;

procedure mostrar_registro(registro:longint);
begin
//mostrar registro
for b1:=0 to no_campos-1 do
writeln(to_campos[b1].nombre+' : ['+truncada(tabla[registro].columna[b1])+']');
end;
procedure mostrar_duplicados(opcion:byte);
var
nsel,co : word;
begin
//mostrar duplicados
for l1:=0 to tregistros-1 do tabla[l1].tipo:=0;
// mascara para optimización de busqueda
setlength(mascara1,tregistros+1000);
for l1:=0 to tregistros-1 do mascara1[l1]:=''; //borramos mascara1
for l1:=0 to tregistros-1 do
    for b1:=0 to no_campos-1 do
    if (to_campos[b1].sel=1) then mascara1[l1]:=mascara1[l1]+tabla[l1].columna[b1]+'#';
tmascara1:=tregistros;
// fin mascara
writeln;
writeln('Buscando coincidentes por campos seleccionados');
writeln;
write('Explorando');
for l1:=0 to tmascara1-1 do
begin
    for l2:=l1 to tmascara1-1 do if (mascara1[l1]=mascara1[l2+1]) then
        case opcion of
        0: begin tabla[l1].tipo:=1;tabla[l2+1].tipo:=1;end;// marca todos los duplicados
        1: begin tabla[l1].tipo:=1; end; // marca los duplicados
        end;

if l1 mod 5000 = 0 then writeln('Procesando [',l1,']');
end;
writeln;
//mostrar
l1:=0;for l2:=0 to tregistros-1 do if tabla[l2].tipo=1 then inc(l1);
writeln;
writeln(' Duplicados : '+inttostr(l1)+' registros (han sido marcados)');
end;
function sumaval(val1,val2,precision:string):string;
var
sm1,sm2  : int64;
valor    : string;
lceros   : word;
begin
//corrijo ceros a la izquierda
lceros:=length(val1);
if lceros<length(val2) then lceros:=length(val2);

sm1:=(strtoint64(fnum(val1,precision))+strtoint64(fnum(val2,precision)));
valor:=ceros(inttostr(sm1),lceros);
result:=valor;
end;

function restaval(val1,val2,precision:string):string;
var
sm1,sm2  : int64;
valor    : string;
lceros   : word;
begin
//corrijo ceros a la izquierda
lceros:=length(val1);
if lceros<length(val2) then lceros:=length(val2);

sm1:=(strtoint64(fnum(val1,precision))-strtoint64(fnum(val2,precision)));
valor:=ceros(inttostr(sm1),lceros);
result:=valor;
end;

function multiplicaval(val1,val2,precision:string):string;
var
sm1,sm2  : int64;
valor    : string;
lceros   : word;
begin
//corrijo ceros a la izquierda
lceros:=length(val1);
if lceros<length(val2) then lceros:=length(val2);

sm1:=(strtoint64(fnum(val1,precision))*strtoint64(fnum(val2,precision)));
valor:=ceros(inttostr(sm1),lceros);
result:=valor;
end;

function mayorque(val1,val2,precision:string):string;
var
valor    : string;
begin

if strtoint64(fnum(val1,precision))>strtoint64(fnum(val2,precision)) then valor:='1' else valor:='0';

result:=valor;
end;

function menorque(val1,val2,precision:string):string;
var
valor    : string;
begin

if strtoint64(fnum(val1,precision))<strtoint64(fnum(val2,precision)) then valor:='1' else valor:='0';

result:=valor;
end;
function igualque(val1,val2,precision:string):string;
var
valor    : string;
begin

if strtoint64(fnum(val1,precision))=strtoint64(fnum(val2,precision)) then valor:='1' else valor:='0';

result:=valor;
end;

function aaaammdd(val1,precision:string):string;
var
sm1,sm2  : int64;
a1,m1,d1 : int64;
valor    : string;
lceros   : word;
begin
//corrijo ceros a la izquierda
lceros:=length(val1);

sm1:=strtoint64(fnum(val1,precision));

a1:=trunc(sm1/10000);
m1:=trunc(sm1/100)-a1*100;
d1:=sm1-a1*10000-m1*100;

sm2:=a1*365+m1*30+d1;

valor:=ceros(inttostr(sm2),lceros);
result:=valor;
end;


function divideval(val1,val2,precision:string):string;
var
sm1          : int64;
sm2,sm3,sm4  : real;
valor        : string;
lceros       : word;
potencia     : word;
begin
//corrijo ceros a la izquierda
lceros:=length(val1);
if lceros<length(val2) then lceros:=length(val2);
if strtoint(fnum(val2,precision))<>0 then
                                     begin
                                          sm2:=strtoint64(fnum(val1,precision));
                                          sm3:=strtoint64(fnum(val2,precision));

                                          sm4:=1;
                                          for potencia:=1 to strtoint(precision) do sm4:=sm4*10;

                                          sm1:=trunc(sm2/sm3*sm4);
                                          valor:=ceros(inttostr(sm1),lceros);
                                     end
                                     else valor:='div_0_error';


result:=valor;
end;

procedure agrupar_duplicados(opcion:byte);
var
nsel,co : word;
pce     : string;
begin
pce:=to_campos[opcion].longitud;
if pce='ilimitado' then pce:='0';
//primero convertir columna de resultado a formato numero sin decimales
writeln;
writeln('Preparando columna de resultados..');
for l1:=0 to tregistros-1 do
                          tabla[l1].columna[opcion]:=fnum(tabla[l1].columna[opcion],pce);
//agrupar duplicados
// mascara para optimización de busqueda
setlength(mascara1,tregistros+1000);
for l1:=0 to tregistros-1 do mascara1[l1]:=''; //borramos mascara1
for l1:=0 to tregistros-1 do
    for b1:=0 to no_campos-1 do
    if (to_campos[b1].sel=1) then mascara1[l1]:=mascara1[l1]+tabla[l1].columna[b1]+'#';
tmascara1:=tregistros;
// fin mascara
for l1:=0 to tregistros-1 do tabla[l1].tipo:=0;
writeln;
writeln('Agrupar coincidentes por campos seleccionados');
writeln;
write('Explorando');
for l1:=0 to tregistros-1 do tabla[l1].tipo:=1; //comienzo marcando todos
for l1:=0 to tmascara1-1 do
begin
    if (tabla[l1].tipo=1) then
    for l2:=l1+1 to tmascara1-1 do
                                if (tabla[l2].tipo=1) and (mascara1[l1]=mascara1[l2])
                                                      then begin
                                                           //almacenar la suma en el primero
                                                           tabla[l1].columna[opcion]:= sumaval(tabla[l1].columna[opcion],tabla[l2].columna[opcion],'0');
                                                           tabla[l2].tipo:=2;
                                                           end;


if l1 mod 5000 = 0 then writeln('Procesando [',l1,']');
end;
writeln;
//borrar los sobrantes
l2:=tregistros;l1:=0;
repeat;
          if tabla[l1].tipo=2 then
                               begin
                               //eliminar sobrante
                               tabla[l1].tipo:=tabla[l2-1].tipo;
                               for b1:=0 to 512 do tabla[l1].columna[b1]:=tabla[l2-1].columna[b1];
                               dec(l2);dec(l1);
                               end else
                                   begin
                                   //cambiar el marcado a 0
                                   tabla[l1].tipo:=0;
                                   end;
inc(l1);
until l1>=l2;
tregistros:=l2;
//prepara resultados con decimales
writeln;
if pce<>'0' then
begin
writeln('Aplicando formato decimal a resultados..');
for l1:=0 to tregistros-1 do
                           tabla[l1].columna[opcion]:=fcoma(tabla[l1].columna[opcion],strtoint(pce),',');
end;
//resultado
writeln;
writeln(' Registros resultantes: '+inttostr(tregistros));
end;

procedure mostrar_columna(r1,r2,col:longint);
begin
//mostrar columna
for l1:=r1 to r2 do
writeln(inttostr(l1)+' - '+truncada(tabla[l1].columna[col]));
end;
procedure guardar(nombre:string);
var
configuracion : text;
begin
assignfile(configuracion,nombre);
rewrite(configuracion);
writeln(configuracion,nombre_origen);
writeln(configuracion,nombre_destino);
for b1:=0 to no_campos-1 do
begin
writeln(configuracion,to_campos[b1].nombre);
writeln(configuracion,to_campos[b1].tipo);
writeln(configuracion,to_campos[b1].longitud);
writeln(configuracion,to_campos[b1].formula);
writeln(configuracion,to_campos[b1].nnombre);
end;
closefile(configuracion);
end;
procedure cargar(nombre:string);
var
configuracion : text;
campo,campo1,campo2,campo3,campo4,campo5 : string;
begin
assignfile(configuracion,nombre);
reset(configuracion);
readln(configuracion,nombre_origen);
readln(configuracion,nombre_destino);
no_campos:=tcolumnas;write('.');
for b1:=0 to 512 do
 begin
 to_campos[b1].nombre:='#nulo#';
 to_campos[b1].tipo:='anular';
 to_campos[b1].longitud:='ilimitado';
 to_campos[b1].formula:='';
 to_campos[b1].nnombre:='';
 end;
if not eof(configuracion) then
while not eof(configuracion) do
begin
readln(configuracion,campo1);
readln(configuracion,campo2);
readln(configuracion,campo3);
readln(configuracion,campo4);
readln(configuracion,campo5);
b1:=0;repeat;inc(b1); until (tabla[0].columna[b1-1]=campo1) or (b1>512);
if b1<=512 then
begin
to_campos[b1-1].nombre:=campo1;
to_campos[b1-1].tipo:=campo2;
to_campos[b1-1].longitud:=campo3;
to_campos[b1-1].formula:=campo4;
to_campos[b1-1].nnombre:=campo5;

end else
    begin
    to_campos[no_campos].nombre:=campo1;
    to_campos[no_campos].tipo:=campo2;
    to_campos[no_campos].longitud:=campo3;
    to_campos[no_campos].formula:=campo4;
    to_campos[no_campos].nnombre:=campo5;
    inc(no_campos);
    end;
write('.');
end;
closefile(configuracion);
end;

function textos(cadena: string;longitud:integer):string;
var
valor    : string;
posicion,origenp : word;
begin
//si la cadena es de tamaño inferior al deseado añade espacios detrás
if (length(cadena)<abs(longitud)) then
begin
valor:=cadena;origenp:=abs(longitud)-length(cadena);
repeat;
valor:=valor+' ';dec(origenp);
until origenp=0;
end;

//si la cadena es mayor al deseado corta por delante si longitud es positivo
if (length(cadena)>abs(longitud)) and (longitud>0) then
begin
valor:='';posicion:=longitud; origenp:=length(cadena);
repeat;
valor:=cadena[origenp+posicion-longitud]+valor;dec(posicion);
until posicion=0;
end;

//si la cadena es mayor al deseado corta por detras si longitud es negativo  v62
if (length(cadena)>abs(longitud)) and (longitud<0) then
begin
valor:='';posicion:=1; origenp:=abs(longitud)+1;
repeat;
valor:=valor+cadena[posicion];inc(posicion);
until posicion>=origenp;
end;

//si la cadena mide exactamente lo mimo, no se toca
if length(cadena)=longitud then valor:=cadena;

result:=valor;
end;
function snumero(cadena: string;longitud:word):string;
var
valor : string;
sn1    : word;
begin
valor:='';
if length(cadena)>0 then
for sn1:=1 to length(cadena) do
if (cadena[sn1]='0') or (cadena[sn1]='1') or (cadena[sn1]='2') or (cadena[sn1]='3') or (cadena[sn1]='4') or (cadena[sn1]='5') or (cadena[sn1]='6')
or (cadena[sn1]='7') or (cadena[sn1]='8') or (cadena[sn1]='9') then valor:=valor+cadena[sn1];

if (length(valor)<longitud) and (longitud>0) then
repeat;
valor:='0'+valor;
until length(valor)=longitud;
result:=valor;
end;
function fechaansi(cadena: string;xxformato:byte):string;
var
valor,af1,mf1,df1 : string;
sn1    : word;
begin
valor:=cadena;
if length(valor)=10 then
begin
// entrada solo DD/MM/AAAA
af1:=valor[7];
af1:=af1+valor[8];
af1:=af1+valor[9];
af1:=af1+valor[10];

mf1:=valor[4];
mf1:=mf1+valor[5];

df1:=valor[1];
df1:=df1+valor[2];

end;

case xxformato of

0: valor:=af1+mf1+df1;
1: valor:=af1+mf1;
2: valor:=af1;
3: valor:=mf1;
4: valor:=df1;
5: valor:=df1+mf1+af1;
6: valor:=mf1+af1;

end;

result:=valor;
end;
function fechax(cadena,xxformato: string):string;
var
valor,af1,mf1,df1 : string;
aa,bb,cc : string;
na,nb,nc : word;
sn1    : word;
opcion : char;
begin
valor:=cadena;

opcion:=xxformato[1];// tipo de entrada

// Limpiar fecha de entrada
// Modelo 1 Procesamos la cadena buscando los tres cuerpos de la fecha aa / bb / cc (dia / mes / año) tres cadenas que pueden luego descolocarse

sn1:=1;

aa:=''; if sn1<length(valor) then while (sn1<length(valor)) and (valor[sn1]<>'/') and (valor[sn1]<>'-') do begin aa:=aa+valor[sn1];inc(sn1);  end; inc(sn1);
bb:=''; if sn1<length(valor) then while (sn1<length(valor)) and (valor[sn1]<>'/') and (valor[sn1]<>'-') do begin bb:=bb+valor[sn1];inc(sn1);  end; inc(sn1);
cc:=''; if sn1<=length(valor) then while (sn1<=length(valor)) and ((valor[sn1]='1') or (valor[sn1]='2') or (valor[sn1]='3') or (valor[sn1]='4') or (valor[sn1]='5') or (valor[sn1]='6') or (valor[sn1]='7') or (valor[sn1]='8') or (valor[sn1]='9') or (valor[sn1]='0')) do begin cc:=cc+valor[sn1];inc(sn1);  end;

na:=strtoint(snumero(aa,2));
nb:=strtoint(snumero(bb,2));
nc:=strtoint(snumero(cc,2));

// Modelo 2
// Damos por hecho que son fechas ansi o similar
valor:=valor+'########';

// formato de entrada

case opcion of

'1': begin
   // automático
   if na>31 then
            begin
            // completamos en base a aaaa/bb/cc
            af1:=aa;
            mf1:=bb;
            df1:=cc;
            //aplicamsos unas correcciones
            if nb>12 then
                     begin
                     // asumimos aaaa/dd/mm
                     df1:=bb;
                     mf1:=cc;
                     end;

            if nc>12 then
                     begin
                     // asumimos aaaa/mm/dd
                     df1:=cc;
                     mf1:=bb;
                     end;
            end;

   if nb>31 then
            begin
            // completamos en base a mm/aa/dd
            af1:=bb;
            mf1:=aa;
            df1:=cc;
            //aplicamsos unas correcciones
            if na>12 then
                     begin
                     // asumimos dd/aa/mm
                     df1:=aa;
                     mf1:=cc;
                     end;

            if nc>12 then
                     begin
                     // asumimos mm/aa/dd
                     df1:=cc;
                     mf1:=aa;
                     end;

            end;

   if nc>31 then
            begin
            // completamos en base a dd/mm/aaaa
            af1:=cc;
            mf1:=bb;
            df1:=aa;
            //aplicamsos unas correcciones
            if na>12 then
                     begin
                     // asumimos dd/mm/aaaa
                     df1:=aa;
                     mf1:=bb;
                     end;

            if nb>12 then
                     begin
                     // asumimos mm/dd/aaaa
                     df1:=bb;
                     mf1:=aa;
                     end;
            end;



   end;

'2': Begin
   // es DD/MM/AAAA
   df1:=aa;
   mf1:=bb;
   af1:=cc;
   end;
'3': Begin
   // es AAAA/MM/DD
   df1:=cc;
   mf1:=bb;
   af1:=aa;
   end;
'4': Begin
   // es AAAA/DD/MM
   df1:=bb;
   mf1:=cc;
   af1:=aa;
   end;
'5': Begin
   // es MM/DD/AAAA
   df1:=bb;
   mf1:=aa;
   af1:=cc;
   end;
'6': Begin
   // es AAAAMMDD
   af1:=valor[1]+valor[2]+valor[3]+valor[4];
   mf1:=valor[5]+valor[6];
   df1:=valor[7]+valor[8];
   end;
'7': Begin
   // es AAAADDMM
   af1:=valor[1]+valor[2]+valor[3]+valor[4];
   df1:=valor[5]+valor[6];
   mf1:=valor[7]+valor[8];
   end;
'8': Begin
   // es DDMMAAAA
   af1:=valor[5]+valor[6]+valor[7]+valor[8];
   mf1:=valor[3]+valor[4];
   df1:=valor[1]+valor[2];
   end;
'9': Begin
   // es MMDDAAAA
   af1:=valor[5]+valor[6]+valor[7]+valor[8];
   df1:=valor[3]+valor[4];
   mf1:=valor[1]+valor[2];
   end;
end;

// formato de salida

opcion:=xxformato[2];
case opcion of

'0': valor:=af1+'/'+mf1+'/'+df1;
'1': valor:=af1+'/'+mf1;
'2': valor:=af1;
'3': valor:=mf1;
'4': valor:=df1;
'5': valor:=df1+'/'+mf1+'/'+af1;
'6': valor:=mf1+'/'+af1;

end;

result:=valor;
end;
function sentero(cadena: string;longitud:word):string;
var
valor : string;
sn1,ltd1   : word;
signo : char;
begin
// superentero
valor:='';signo:='+';ltd1:=longitud-1;
if length(cadena)>0 then
for sn1:=1 to length(cadena) do

if (cadena[sn1]='0') or (cadena[sn1]='1') or (cadena[sn1]='2') or (cadena[sn1]='3') or (cadena[sn1]='4') or (cadena[sn1]='5') or (cadena[sn1]='6')
or (cadena[sn1]='7') or (cadena[sn1]='8') or (cadena[sn1]='9') then valor:=valor+cadena[sn1]
                                                               else if cadena[sn1]='-' then signo:='-';


if (length(valor)<ltd1) and (ltd1>0) then
repeat;
valor:='0'+valor;
until length(valor)=ltd1;
result:=signo+valor;
end;

function xvalor(campo:string;registro:longint):string;
var
f1,f2 : longint;
fs1   : string;
begin
//coge valores en base al primer registro de la tabla
f2:=0;
for f1:=0 to no_campos-1 do
    if campo=tabla[0].columna[f1] then
                                  fs1:=tabla[registro].columna[f1];
result:=fs1;
end;
function xtiempo:string;
var
  Year,Month,Day,WDay : word;
begin
  GetDate(Year,Month,Day,WDay);
  xtiempo:=snumero(inttostr(day),2)+'/'+snumero(inttostr(Month),2)+'/'+snumero(inttostr(year),4);
end;
function xformula(formula:string;registro:longint;precision:string):string;
var
f1,f2,f3 : longint;
fs1,fs2,fs3   : string;
begin
//formulas campos entre signos { y }
//no organiza la operación ni admite parentesis. acumula las operaciones una a una
//variable fs3 de operación. validos *,/,+,-
//otras funciones:
// $variable$ - funciones definidas
// > - mayor que
// < - menor que
// = - igual que
// @ - longitud cadena
// # - Fecha AAAAMMDD (formato ASNI)
// % - Salta siguiente
fs1:='';f2:=1;
if precision='ilimitado' then precision:='0';
fs3:='';f3:=0;
if length(formula)>0 then
repeat;
//variables
if f3>0 then dec(f3);

case formula[f2] of
'$': begin
     //Funciones predefinidas
     fs2:='';inc(f2);
     repeat;
     fs2:=fs2+formula[f2];
     inc(f2);
     until formula[f2]='$';
     //fecha actual
     if fs2='fecha' then fs1:=fs1+xtiempo;
     f3:=1;
     end;
'"': begin
     //Funciones predefinidas
     fs2:='';inc(f2);
     repeat;
     fs2:=fs2+formula[f2];
     inc(f2);
     until formula[f2]='"';
     //operar con valor fijo

     if fs3='+' then fs1:=sumaval(fs1,fs2,precision);
     if fs3='-' then fs1:=restaval(fs1,fs2,precision);
     if fs3='*' then fs1:=multiplicaval(fs1,fs2,precision);
     if fs3='/' then fs1:=divideval(fs1,fs2,precision);
     if fs3='#' then fs1:=aaaammdd(fs2,precision);
     if fs3='<' then fs1:=menorque(fs1,fs2,precision);
     if fs3='>' then fs1:=mayorque(fs1,fs2,precision);
     if fs3='=' then fs1:=igualque(fs1,fs2,precision);

     if fs3='' then fs1:=fs1+fs2;
     f3:=1;fs3:='';
     end;
'{': begin
     //Funciones de operaciones
     fs2:='';inc(f2);
     repeat;
     fs2:=fs2+formula[f2];
     inc(f2);
     until formula[f2]='}';

     //operar
     if fs3='+' then fs1:=sumaval(fs1,xvalor(fs2,registro),precision);
     if fs3='-' then fs1:=restaval(fs1,xvalor(fs2,registro),precision);
     if fs3='*' then fs1:=multiplicaval(fs1,xvalor(fs2,registro),precision);
     if fs3='/' then fs1:=divideval(fs1,xvalor(fs2,registro),precision);
     if fs3='#' then fs1:=aaaammdd(xvalor(fs2,registro),precision);
     if fs3='<' then fs1:=menorque(fs1,xvalor(fs2,registro),precision);
     if fs3='>' then fs1:=mayorque(fs1,xvalor(fs2,registro),precision);
     if fs3='=' then fs1:=igualque(fs1,xvalor(fs2,registro),precision);

     if fs3=''  then fs1:=fs1+xvalor(fs2,registro);
     f3:=1;fs3:='';
     end;
'+': begin fs3:='+';f3:=1;end;
'-': begin fs3:='-';f3:=1;end;
'*': begin fs3:='*';f3:=1;end;
'/': begin fs3:='/';f3:=1;end;
'<': begin fs3:='<';f3:=1;end;
'>': begin fs3:='>';f3:=1;end;
'@': begin fs3:='@';f3:=1;end;
'#': begin fs3:='#';f3:=1;end;
'=': begin fs3:='=';f3:=1;end;
'%': begin inc(f2);end;

end;

if (f3=0) then fs1:=fs1+formula[f2];

inc(f2);
until (f2>length(formula));
result:=fs1;
end;
procedure exportar(forma: longint;ndestino:string;primera:longint);
var
destino  : text;
matriz   : string;
objeto   : string;
begin
//exportar
writeln;
writeln(' Separador de columna: chr ',schr);
writeln;
assignfile(destino,ndestino);
rewrite(destino);

//campos
if primera=1 then
begin
matriz:='';
for l1:=0 to no_campos-1 do
    begin
    if to_campos[l1].tipo<>'anular' then
        begin
        //aplicar
                  if to_campos[l1].nnombre='' then
                                              begin
                                              if matriz<>'' then matriz:=matriz+chr(schr);
                                              matriz:=matriz+to_campos[l1].nombre;
                                              end
                                                 else
                                                 begin
                                                 if matriz<>'' then matriz:=matriz+chr(schr);
                                                 matriz:=matriz+to_campos[l1].nnombre;
                                                 end;
        end;
    
    end;
writeln(destino,matriz);
end;
//registros
for l1:=1 to tregistros-1 do
    begin
    matriz:='';
    if ((tabla[l1].tipo=0) and (forma=2)) or ((tabla[l1].tipo>0) and (forma=1)) or
       (forma=0)
       then
    begin
    for l2:=0 to no_campos-1 do
        begin
        if to_campos[l2].tipo<>'anular' then
        begin
        //aplicar formula
        if to_campos[l2].formula='' then objeto:=tabla[l1].columna[l2]
                                    else objeto:=xformula(to_campos[l2].formula,l1,to_campos[l2].longitud);
        
        if (to_campos[l2].tipo='numerico') and (to_campos[l2].longitud<>'ilimitado') then objeto:=fcoma(fnum(objeto,to_campos[l2].longitud),strtoint(to_campos[l2].longitud),',');
        if (to_campos[l2].tipo='numerico') and (to_campos[l2].longitud='ilimitado') then objeto:=fnum(objeto,'0');
        if (to_campos[l2].tipo='texto') and (to_campos[l2].longitud<>'ilimitado') then objeto:=textos(objeto,strtoint(to_campos[l2].longitud));
        if (to_campos[l2].tipo='fansi') and (to_campos[l2].longitud<>'ilimitado') then objeto:=fechaansi(objeto,strtoint(to_campos[l2].longitud));
        if (to_campos[l2].tipo='fecha') and (to_campos[l2].longitud<>'ilimitado') then objeto:=fechax(objeto,to_campos[l2].longitud);
        if (to_campos[l2].tipo='f1900') and (to_campos[l2].longitud<>'ilimitado') then objeto:=fechax(datetostr(incday(strtodate('30/12/1899'),strtoint(snumero(objeto,5)))),'2'+to_campos[l2].longitud);
        if (to_campos[l2].tipo='supernumero') and (to_campos[l2].longitud<>'ilimitado') then objeto:=snumero(objeto,strtoint(to_campos[l2].longitud));
        if (to_campos[l2].tipo='supernumero') and (to_campos[l2].longitud='ilimitado') then objeto:=snumero(objeto,0);
        if (to_campos[l2].tipo='superentero') and (to_campos[l2].longitud<>'ilimitado') then objeto:=sentero(objeto,strtoint(to_campos[l2].longitud));
        if (to_campos[l2].tipo='superentero') and (to_campos[l2].longitud='ilimitado') then objeto:=sentero(objeto,0);
        if (to_campos[l2].tipo='moneda') then objeto:=fcoma(fnum(objeto,'2'),2,',')+' €';
        if (to_campos[l2].tipo='fcoma') and (to_campos[l2].longitud<>'ilimitado') then objeto:=fcoma(objeto,strtoint(to_campos[l2].longitud),',');
        if (to_campos[l2].tipo='fcoma') and (to_campos[l2].longitud='ilimitado') then objeto:=fcoma(objeto,2,',');
        if (to_campos[l2].tipo='sql') and (to_campos[l2].longitud<>'ilimitado') then objeto:=fcoma(fnum(objeto,to_campos[l2].longitud),strtoint(to_campos[l2].longitud),'.');
        if (to_campos[l2].tipo='sql') and (to_campos[l2].longitud='ilimitado') then objeto:=fcoma(fnum(objeto,'2'),2,'.');

        matriz:=matriz+objeto+chr(schr);
        end;
        end;
    setlength(matriz,length(matriz)-1);
    writeln(destino,matriz);
    end;
    if l1 mod 1000 = 0 then writeln('Procesando [',l1,']');
    end;
closefile(destino);
end;
procedure exportar_sql(forma: longint;ndestino:string);
var
destino         : text;
matriz,valores  : string;
objeto          : string;
begin
//exportar
writeln;
writeln(' ** Se exporta fichero formato SQL **');
writeln;
assignfile(destino,ndestino);
rewrite(destino);

//campos

matriz:='';
for l1:=0 to no_campos-1 do
    begin
    if to_campos[l1].tipo<>'anular' then
        begin
        //aplicar
                  if to_campos[l1].nnombre='' then
                                              begin
                                              if matriz<>'' then matriz:=matriz+',';
                                              matriz:=matriz+to_campos[l1].nombre;
                                              end
                                                 else
                                                 begin
                                                 if matriz<>'' then matriz:=matriz+',';
                                                 matriz:=matriz+to_campos[l1].nnombre;
                                                 end;
        end;
    end;
//writeln(destino,matriz);

//registros
for l1:=1 to tregistros-1 do
    begin
    valores:='';
    if ((tabla[l1].tipo=0) and (forma=2)) or ((tabla[l1].tipo>0) and (forma=1)) or
       (forma=0)
       then
    begin
    for l2:=0 to no_campos-1 do
        begin
        if to_campos[l2].tipo<>'anular' then
        begin
        //aplicar formula
        if to_campos[l2].formula='' then objeto:=tabla[l1].columna[l2]
                                    else objeto:=xformula(to_campos[l2].formula,l1,to_campos[l2].longitud);

        if (to_campos[l2].tipo='numerico') and (to_campos[l2].longitud<>'ilimitado') then objeto:=chr(39)+fcoma(fnum(objeto,to_campos[l2].longitud),strtoint(to_campos[l2].longitud),',')+chr(39);
        if (to_campos[l2].tipo='numerico') and (to_campos[l2].longitud='ilimitado') then objeto:=chr(39)+fnum(objeto,'0')+chr(39);
        if (to_campos[l2].tipo='texto') and (to_campos[l2].longitud<>'ilimitado') then objeto:=chr(39)+textos(objeto,strtoint(to_campos[l2].longitud))+chr(39);
        if (to_campos[l2].tipo='texto') and (to_campos[l2].longitud='ilimitado') then objeto:=chr(39)+objeto+chr(39);
        if (to_campos[l2].tipo='fansi') and (to_campos[l2].longitud<>'ilimitado') then objeto:=chr(39)+fechaansi(objeto,strtoint(to_campos[l2].longitud))+chr(39);
        if (to_campos[l2].tipo='fecha') and (to_campos[l2].longitud<>'ilimitado') then objeto:=chr(39)+fechax(objeto,to_campos[l2].longitud)+chr(39);
        if (to_campos[l2].tipo='f1900') and (to_campos[l2].longitud<>'ilimitado') then objeto:=chr(39)+fechax(datetostr(incday(strtodate('30/12/1899'),strtoint(snumero(objeto,5)))),'2'+to_campos[l2].longitud)+chr(39);
        if (to_campos[l2].tipo='supernumero') and (to_campos[l2].longitud<>'ilimitado') then objeto:=chr(39)+snumero(objeto,strtoint(to_campos[l2].longitud))+chr(39);
        if (to_campos[l2].tipo='supernumero') and (to_campos[l2].longitud='ilimitado') then objeto:=chr(39)+snumero(objeto,0)+chr(39);
        if (to_campos[l2].tipo='superentero') and (to_campos[l2].longitud<>'ilimitado') then objeto:=chr(39)+sentero(objeto,strtoint(to_campos[l2].longitud))+chr(39);
        if (to_campos[l2].tipo='superentero') and (to_campos[l2].longitud='ilimitado') then objeto:=chr(39)+sentero(objeto,0)+chr(39);
        if (to_campos[l2].tipo='moneda') then objeto:=chr(39)+fcoma(fnum(objeto,'2'),2,',')+' €'+chr(39);
        if (to_campos[l2].tipo='fcoma') and (to_campos[l2].longitud<>'ilimitado') then objeto:=chr(39)+fcoma(objeto,strtoint(to_campos[l2].longitud),',')+chr(39);
        if (to_campos[l2].tipo='fcoma') and (to_campos[l2].longitud='ilimitado') then objeto:=chr(39)+fcoma(objeto,2,',')+chr(39);
        if (to_campos[l2].tipo='sql') and (to_campos[l2].longitud<>'ilimitado') then objeto:=fcoma(fnum(objeto,to_campos[l2].longitud),strtoint(to_campos[l2].longitud),'.');
        if (to_campos[l2].tipo='sql') and (to_campos[l2].longitud='ilimitado') then objeto:=fcoma(fnum(objeto,'2'),2,'.');

        valores:=valores+objeto+',';
        end;
        end;

    //construyo el insert
    setlength(valores,length(valores)-1);
    valores:='INSERT INTO '+nombre_destino+' ('+matriz+') VALUES ('+valores+');';
    //setlength(valores,length(valores)-1);
    writeln(destino,valores);
    end;
    if l1 mod 1000 = 0 then writeln('Procesando [',l1,']');
    end;
closefile(destino);
end;
procedure exportar_af(forma: longint;ndestino:string;primera:longint);
var
destino : text;
matriz  : string;
objeto  : string;
xorden  : array [0..512] of byte;
ex1,ex2 : word;
begin
//exportar
writeln;
assignfile(destino,ndestino);
rewrite(destino);
// campos si "primera" es 1 entonces es que se incluyen los campos
// proceso que ordena el valor l2 frente al orden correcto
for ex1:=0 to 512 do xorden[ex1]:=999;
if tregistros2>0 then
for ex1:=0 to tregistros2-1 do
                          for ex2:=0 to no_campos-1 do
                             if tabla2[ex1].columna[0]=to_campos[ex2].nombre then xorden[ex1]:=ex2;

//registros
for l1:=1-primera to tregistros-1 do
    begin
    matriz:='';
    if ((tabla[l1].tipo=0) and (forma=2)) or ((tabla[l1].tipo>0) and (forma=1)) or
       (forma=0)
       then
    begin
    for l3:=0 to no_campos-1 do
        begin
        l2:=xorden[l3]; //reordenación del archivo de ancho fijo
        if (to_campos[l2].tipo<>'anular') and (l2<>999) then
        begin
        //aplicar formula
        if to_campos[l2].formula='' then objeto:=tabla[l1].columna[l2]
                                    else objeto:=xformula(to_campos[l2].formula,l1,to_campos[l2].longitud);

        if (to_campos[l2].tipo='numerico') and (to_campos[l2].longitud<>'ilimitado') then objeto:=fcoma(fnum(objeto,to_campos[l2].longitud),strtoint(to_campos[l2].longitud),',');
        if (to_campos[l2].tipo='numerico') and (to_campos[l2].longitud='ilimitado') then objeto:=fnum(objeto,'0');
        if (to_campos[l2].tipo='texto') and (to_campos[l2].longitud<>'ilimitado') then objeto:=textos(objeto,strtoint(to_campos[l2].longitud));
        if (to_campos[l2].tipo='fansi') and (to_campos[l2].longitud<>'ilimitado') then objeto:=fechaansi(objeto,strtoint(to_campos[l2].longitud));
        if (to_campos[l2].tipo='fecha') and (to_campos[l2].longitud<>'ilimitado') then objeto:=fechax(objeto,to_campos[l2].longitud);
        if (to_campos[l2].tipo='f1900') and (to_campos[l2].longitud<>'ilimitado') then objeto:=fechax(datetostr(incday(strtodate('30/12/1899'),strtoint(snumero(objeto,5)))),'2'+to_campos[l2].longitud);
        if (to_campos[l2].tipo='supernumero') and (to_campos[l2].longitud<>'ilimitado') then objeto:=snumero(objeto,strtoint(to_campos[l2].longitud));
        if (to_campos[l2].tipo='supernumero') and (to_campos[l2].longitud='ilimitado') then objeto:=snumero(objeto,0);
        if (to_campos[l2].tipo='superentero') and (to_campos[l2].longitud<>'ilimitado') then objeto:=sentero(objeto,strtoint(to_campos[l2].longitud));
        if (to_campos[l2].tipo='superentero') and (to_campos[l2].longitud='ilimitado') then objeto:=sentero(objeto,0);
        if (to_campos[l2].tipo='moneda') then objeto:=fcoma(fnum(objeto,'2'),2,',')+' €';
        if (to_campos[l2].tipo='fcoma') and (to_campos[l2].longitud<>'ilimitado') then objeto:=fcoma(objeto,strtoint(to_campos[l2].longitud),',');
        if (to_campos[l2].tipo='fcoma') and (to_campos[l2].longitud='ilimitado') then objeto:=fcoma(objeto,2,',');
        if (to_campos[l2].tipo='sql') and (to_campos[l2].longitud<>'ilimitado') then objeto:=fcoma(fnum(objeto,to_campos[l2].longitud),strtoint(to_campos[l2].longitud),'.');
        if (to_campos[l2].tipo='sql') and (to_campos[l2].longitud='ilimitado') then objeto:=fcoma(fnum(objeto,'2'),2,'.');

        matriz:=matriz+objeto;
        end;
        end;
    writeln(destino,matriz);
    writeln(matriz);
    end;
    if l1 mod 1000 = 0 then writeln('Procesando [',l1,']');
    end;
closefile(destino);
end;
procedure ss_taux(campot:byte);//señala el campo de destino
var
nsel,co : word;
xcampo  : string;
subcamp : array [0..512] of byte; // mapa de campos coincidentes
begin
nsel:=0;
for b1:=0 to no_campos-1 do if to_campos[b1].sel=1 then inc(nsel);
for l1:=0 to tregistros-1 do tabla[l1].tipo:=0;
// mapa de subcampos
for b1:=0 to 512 do subcamp[b1]:=255; //anular subcampo
for b1:=0 to no_campos-1 do
    for b2:=0 to tcolumnas2-1 do
        begin
        if to_campos[b1].nombre=tabla2[0].columna[b2] then
                                                      begin
                                                      subcamp[b1]:=b2;
                                                      end;
        end;
// end mapa
writeln;
writeln('Buscando coincidentes para sustituir...');
writeln;
write('Explorando');writeln;
for l1:=0 to tregistros-1 do
    begin

    for l2:=0 to tregistros2-1 do
        begin
        // comparando entre tablas
        co:=0;
        for b1:=0 to no_campos-1 do
            begin
            if (to_campos[b1].sel=1) and (subcamp[b1]<>255) then
               begin
               if tabla[l1].columna[b1]=tabla2[l2].columna[subcamp[b1]] then begin
                                                                             inc(co);
                                                                             end;
               end;
            end;

        if co=nsel then begin
                        //marcar tabla principal
                        tabla[l1].tipo:=1;
                        //sustituir el valor
                        tabla[l1].columna[campot]:=tabla2[l2].columna[subcamp[campot]];
                        end;


        end;
    if l1 mod 1000 = 0 then writeln('Procesando [',l1,']');
    end;
writeln;
//mostrar
l1:=0;for l2:=0 to tregistros-1 do if tabla[l2].tipo=1 then inc(l1);
writeln;
writeln(' Sustituidos : '+inttostr(l1)+' registros (y han sido marcados)');
end;
procedure ssi_taux(campod,campot:byte);//señala campo destino y origen de datos desde taux
var
nsel,co : word;
xcampo  : string;
subcamp : array [0..512] of byte; // mapa de campos coincidentes
begin
nsel:=0;
for b1:=0 to no_campos-1 do if to_campos[b1].sel=1 then inc(nsel);
for l1:=0 to tregistros-1 do tabla[l1].tipo:=0;
// mapa de subcampos
for b1:=0 to 512 do subcamp[b1]:=255; //anular subcampo
for b1:=0 to no_campos-1 do
    for b2:=0 to tcolumnas2-1 do
        begin
        if to_campos[b1].nombre=tabla2[0].columna[b2] then
                                                      begin
                                                      subcamp[b1]:=b2;
                                                      end;
        end;
// end mapa
writeln;
writeln('Buscando coincidentes para intercambiar...');
writeln;
write('Explorando');writeln;
for l1:=0 to tregistros-1 do
    begin

    for l2:=0 to tregistros2-1 do
        begin
        // comparando entre tablas
        co:=0;
        for b1:=0 to no_campos-1 do
            begin
            if (to_campos[b1].sel=1) and (subcamp[b1]<>255) then
               begin
               if tabla[l1].columna[b1]=tabla2[l2].columna[subcamp[b1]] then begin
                                                                             inc(co);
                                                                             end;
               end;
            end;

        if co=nsel then begin
                        //marcar tabla principal
                        tabla[l1].tipo:=1;
                        //sustituir el valor
                        tabla[l1].columna[campod]:=tabla2[l2].columna[campot]; // campot directo por valor de tabla2 auxiliar
                        end;


        end;
    if l1 mod 1000 = 0 then writeln('Procesando [',l1,']');
    end;
writeln;
//mostrar
l1:=0;for l2:=0 to tregistros-1 do if tabla[l2].tipo=1 then inc(l1);
writeln;
writeln(' Intercambiados : '+inttostr(l1)+' registros (y han sido marcados)');
end;
procedure ssporcion_taux(campot:byte);//señala el campo de destino
var
nsel,co,posi : word;
xcampo       : string;
subcamp      : array [0..512] of byte; // mapa de campos coincidentes
begin
nsel:=0;
for b1:=0 to no_campos-1 do if to_campos[b1].sel=1 then inc(nsel);
for l1:=0 to tregistros-1 do tabla[l1].tipo:=0;
// mapa de subcampos
for b1:=0 to 512 do subcamp[b1]:=0; //todo subcampo apunta a columna unica

// end mapa
writeln;
writeln('Buscando coincidentes parciales para sustituir...');
writeln;
write('Explorando');writeln;
for l1:=0 to tregistros-1 do
    begin

    for l2:=0 to tregistros2-1 do
        begin
        // comparando entre tablas
        co:=0;
        for b1:=0 to no_campos-1 do
            begin
            if (to_campos[b1].sel=1) and (subcamp[b1]<>255) then
               begin
               posi:=buscapos(tabla[l1].columna[b1],tabla2[l2].columna[subcamp[b1]],1);
               if posi>0 then co:=posi+length(tabla[l1].columna[b1]);
               end;
            end;

        if co>0 then begin
                        //marcar tabla principal
                        tabla[l1].tipo:=1;
                        //sustituir el valor desde la posición deseada
                        tabla[l1].columna[campot]:='';
                        l3:=0;
                        if co+l3<=length(tabla2[l2].columna[subcamp[campot]]) then
                        while (co+l3<=length(tabla2[l2].columna[subcamp[campot]]))
                        do begin
                           tabla[l1].columna[campot]:=tabla[l1].columna[campot]+tabla2[l2].columna[subcamp[campot]][co+l3];
                           inc(l3);
                           end;
                        end;


        end;
    if l1 mod 1000 = 0 then writeln('Procesando [',l1,']');
    end;
writeln;
//mostrar
l1:=0;for l2:=0 to tregistros-1 do if tabla[l2].tipo=1 then inc(l1);
writeln;
writeln(' Sustituidos : '+inttostr(l1)+' registros (y han sido marcados)');
end;
procedure union_taux;
var
nsel,co : word;
xcampo  : string;
subcamp : array [0..512] of byte; // mapa de campos coincidentes
begin
// lo primero es copiar los campos no seleccionados
b3:=no_campos;
for b2:=0 to tcolumnas2-1 do
        begin
        co:=0;
        for b1:=0 to no_campos-1 do
        if (to_campos[b1].nombre=tabla2[0].columna[b2]) then
                                                      begin
                                                      inc(co);
                                                      end;
        if co=0 then
                begin
                //campo nuevo añado
                to_campos[b3].nombre:=tabla2[0].columna[b2];
                to_campos[b3].tipo:='texto';
                to_campos[b3].longitud:='ilimitado';
                to_campos[b3].formula:='';
                to_campos[b3].nnombre:='';
                to_campos[b3].sel:=0;
                inc(b3);
                end;
        end;
no_campos:=b3;
//inicio
nsel:=0;
for b1:=0 to no_campos-1 do if to_campos[b1].sel=1 then inc(nsel);
for l1:=0 to tregistros-1 do tabla[l1].tipo:=0;
// mapa de subcampos
for b1:=0 to 512 do subcamp[b1]:=255; //anular subcampo
for b1:=0 to no_campos-1 do
    for b2:=0 to tcolumnas2-1 do
        begin
        if to_campos[b1].nombre=tabla2[0].columna[b2] then
                                                      begin
                                                      subcamp[b1]:=b2;
                                                      end;
        end;
// end mapa
writeln;
writeln('Buscando coincidentes para unir tablas...');
writeln;
write('Explorando');
for l1:=0 to tregistros-1 do
    begin

    for l2:=0 to tregistros2-1 do
        begin
        // comparando entre tablas
        co:=0;
        for b1:=0 to no_campos-1 do
            begin
            if (to_campos[b1].sel=1) and (subcamp[b1]<>255) then
               begin
               if tabla[l1].columna[b1]=tabla2[l2].columna[subcamp[b1]] then begin
                                                                             inc(co);
                                                                             end;
               end;
            end;

        if co=nsel then begin
                        //marcar tabla principal
                        tabla[l1].tipo:=1;
                        //sustituyendo valor
                        for b3:=0 to no_campos-1 do
                        if (to_campos[b3].sel=0) and (subcamp[b3]<>255) then tabla[l1].columna[b3]:=tabla2[l2].columna[subcamp[b3]];
                        end;


        end;
    if l1 mod 1000 = 0 then writeln('Procesando [',l1,']');
    end;
writeln;
//mostrar
l1:=0;for l2:=0 to tregistros-1 do if tabla[l2].tipo=1 then inc(l1);
writeln;
writeln(' Resultado : '+inttostr(l1)+' registros unidos (y han sido marcados)');
end;
procedure marcar_coincidentes;//entre tablas
var
nsel,co : word;
xcampo  : string;
subcamp : array [0..512] of byte; // mapa de campos coincidentes
begin
nsel:=0;
for b1:=0 to no_campos-1 do if to_campos[b1].sel=1 then inc(nsel);
for l1:=0 to tregistros-1 do tabla[l1].tipo:=0; //borramos marcados
// mapa de subcampos
for b1:=0 to 512 do subcamp[b1]:=255; //anular subcampo
for b1:=0 to no_campos-1 do
    for b2:=0 to tcolumnas2-1 do
        begin
        if to_campos[b1].nombre=tabla2[0].columna[b2] then
                                                      begin
                                                      subcamp[b1]:=b2;
                                                      end;
        end;
// end mapa
// mascara para optimización de busqueda
setlength(mascara1,tregistros+1000);
for l1:=0 to tregistros-1 do mascara1[l1]:=''; //borramos mascara1
for l1:=0 to tregistros-1 do
    for b1:=0 to no_campos-1 do
    if (to_campos[b1].sel=1) and (subcamp[b1]<>255) then mascara1[l1]:=mascara1[l1]+tabla[l1].columna[b1]+'#';
tmascara1:=tregistros;
setlength(mascara2,tregistros2+1000);
for l1:=0 to tregistros2-1 do mascara2[l1]:=''; //borramos mascara2
for l1:=0 to tregistros2-1 do
    for b1:=0 to no_campos-1 do
    if (to_campos[b1].sel=1) and (subcamp[b1]<>255) then mascara2[l1]:=mascara2[l1]+tabla2[l1].columna[subcamp[b1]]+'#';
tmascara2:=tregistros2;
// end mascara
writeln;
writeln('Buscando coincidentes entre tablas');
writeln;
writeln('Explorando');


// comparando entre tablas
    for l2:=0 to tmascara2-1 do
    begin
    for l1:=0 to tmascara1-1 do if mascara1[l1]=mascara2[l2] then tabla[l1].tipo:=1;

    if l2 mod 1000 = 0 then writeln('Procesando [',l2,' de ',tmascara2-1,']');
    end;
writeln;
//mostrar
l1:=0;for l2:=0 to tregistros-1 do if tabla[l2].tipo=1 then inc(l1);
writeln;
writeln(' Duplicados : '+inttostr(l1)+' registros (han sido marcados)');
end;
procedure agregar_aux(opcion: longint);
var
xcampo  : string;
subcamp : array [0..512] of byte; // mapa de campos coincidentes
begin
// mapa de subcampos
writeln('Relación de campos:');writeln;
for b1:=0 to 512 do subcamp[b1]:=255; //anular subcampo
for b1:=0 to no_campos-1 do
    for b2:=0 to tcolumnas2-1 do
        begin
        if to_campos[b1].nombre=tabla2[0].columna[b2] then
                                                      begin
                                                      subcamp[b1]:=b2;
                                                      writeln('Campo rel. '+to_campos[b1].nombre+'<->'+tabla2[0].columna[b2]);
                                                      end;
        end;
// end mapa
writeln;
writeln('Agregando a tabla principal registros de taux');
writeln;
write('Trabajando');
for l1:=opcion to tregistros2-1 do
    begin
    if (tregistros+l1>=length(tabla)) then setlength(tabla,tregistros+l1+1000);
    for b1:=0 to tcolumnas-1 do
        if (subcamp[b1]<>255) then
                              tabla[tregistros+l1-opcion].columna[b1]:=tabla2[l1].columna[subcamp[b1]];
    if l1 mod 1000 = 0 then writeln('Procesando [',l1,']');
    end;
tregistros:=tregistros+tregistros2-opcion;
writeln;
writeln(' Agregados :'+inttostr(tregistros2-opcion)+ ' registros');
writeln;
end;
function sestring(cadena:string):string;
var
final: string;
begin
// quitar espacios finales de celda
final:=cadena;
if length(final)>1 then
repeat
if (length(final)>1) and (final[length(final)]=' ') then setlength(final,length(final)-1);
until (final[length(final)]<>' ') or (length(final)<=1);
if final=' ' then final:='';
result:=final;
end;
function seistring(cadena:string):string;
var
final: string;
begin
//quitar espacios iniciales de celda
final:='';
b2:=1;
if length(cadena)>1 then
begin
if cadena[b2]=' ' then while (cadena[b2]=' ') and (b2<=length(cadena)) do inc(b2);
while (b2<=length(cadena)) do begin final:=final+cadena[b2];inc(b2); end;
end else
    final:=cadena;
if final=' ' then final:='';
result:=final;
end;
function ssstring(cadena:string;cb,cn:byte):string;
var
xses : word;
final: string;
begin
//sustituir caracteres de celda
final:=cadena;
if length(final)>1 then
for xses:=1 to length(final) do
                              if final[xses]=chr(cb) then final[xses]:=chr(cn);

result:=final;
end;
procedure borrar_espacios;
var
cinter : string;
begin
writeln('Localizando registros con espacios...');l2:=0;
if tregistros=0 then exit;
for l1:=0 to tregistros-1 do
    for b1:=0 to no_campos-1 do tabla[l1].columna[b1]:=sestring(tabla[l1].columna[b1]);
writeln;
writeln(' Procesados : '+inttostr(tregistros*no_campos)+' campos');
end;
procedure borrar_tespacios;
var
cinter : string;
begin
writeln('Localizando registros con espacios en inicio y final de campo...');l2:=0;
if tregistros=0 then exit;
for l1:=0 to tregistros-1 do
    for b1:=0 to no_campos-1 do tabla[l1].columna[b1]:=seistring(tabla[l1].columna[b1]);
writeln;
writeln(' Procesados : '+inttostr(tregistros*no_campos)+' campos');
end;
procedure localizarexcesolongitud(lmaxima:word);
var
cinter : string;
begin
for l1:=0 to tregistros-1 do tabla[l1].tipo:=0;
writeln('Localizando registros con exceso de longitud...');l2:=0;
if tregistros=0 then exit;
l2:=0;
for l1:=0 to tregistros-1 do
    begin
    cinter:='';
    for b1:=0 to no_campos-1 do cinter:=cinter+tabla[l1].columna[b1];
    if length(cinter)>lmaxima then begin tabla[l1].tipo:=1; inc(l2);end;
    end;
writeln;
writeln(' Localizados : '+inttostr(l2));
writeln(' Procesados  : '+inttostr(tregistros));
end;
procedure filtrarchr(cb,cn:byte);
var
cinter : string;
begin
writeln('Localizando registros y sustituyendo...');l2:=0;
if tregistros=0 then exit;
for l1:=0 to tregistros-1 do
    for b1:=0 to no_campos-1 do tabla[l1].columna[b1]:=ssstring(tabla[l1].columna[b1],cb,cn);
writeln;
writeln(' Procesados : '+inttostr(tregistros*no_campos)+' campos');
end;
procedure filtrarcad(cadena:string);
var
cinter : string;
begin
// marcar registros con una cadena determinada
for l1:=0 to tregistros-1 do tabla[l1].tipo:=0; //borramos marcados

writeln('Localizando registros con clave y marcando...');l2:=0;
if tregistros=0 then exit;
for l1:=0 to tregistros-1 do
    for b1:=0 to no_campos-1 do
    if to_campos[b1].sel=1 then
                           if buscapos(cadena,tabla[l1].columna[b1],0)>0 then tabla[l1].tipo:=1;
writeln;
writeln(' Procesados : '+inttostr(tregistros)+' registros');
end;
procedure fmayorque(cadena:string);
var
cinter : string;
begin
// marcar registros con valor mayor que cadena
for l1:=0 to tregistros-1 do tabla[l1].tipo:=0; //borramos marcados

writeln('Localizando registros con valor mayor que valor y marcando...');l2:=0;
if tregistros=0 then exit;
for l1:=0 to tregistros-1 do
    for b1:=0 to no_campos-1 do
    if to_campos[b1].sel=1 then
                           if strtoint64(fnum(tabla[l1].columna[b1],to_campos[b1].longitud))>strtoint64(fnum(cadena,to_campos[b1].longitud)) then tabla[l1].tipo:=1;

writeln;
writeln(' Procesados : '+inttostr(tregistros)+' registros');
end;
procedure fmenorque(cadena:string);
var
cinter : string;
begin
// marcar registros con valor mayor que cadena
for l1:=0 to tregistros-1 do tabla[l1].tipo:=0; //borramos marcados

writeln('Localizando registros y marcando...');l2:=0;
if tregistros=0 then exit;
for l1:=0 to tregistros-1 do
    for b1:=0 to no_campos-1 do
    if to_campos[b1].sel=1 then
                           if strtoint64(fnum(tabla[l1].columna[b1],to_campos[b1].longitud))<strtoint64(fnum(cadena,to_campos[b1].longitud)) then tabla[l1].tipo:=1;
writeln;
writeln(' Procesados : '+inttostr(tregistros)+' registros');
end;
procedure marcar_nulos;
var
cadena : string;
begin
writeln('Localizando registros nulos...');l2:=0;
if tregistros=0 then exit;
for l1:=0 to tregistros-1 do
    begin
    cadena:='';
    for b1:=0 to no_campos-1 do cadena:=cadena+tabla[l1].columna[b1];
    if cadena='' then begin
                      tabla[l1].tipo:=1;//es nula
                      inc(l2);
                      end;
    end;
writeln;
writeln(' Registros nulos : '+inttostr(l2)+' (han sido marcados)');
end;
procedure marcar_camposnulos;
var
cadena : string;
begin
writeln('Localizando registros con campos nulos...');l2:=0;
if tregistros=0 then exit;
for l1:=0 to tregistros-1 do
    begin
    cadena:='';
    for b1:=0 to no_campos-1 do if to_campos[b1].sel=1 then cadena:=cadena+tabla[l1].columna[b1];
    if cadena='' then begin
                      tabla[l1].tipo:=1;//es nula
                      inc(l2);
                      end;
    end;
writeln;
writeln(' Registros campos nulos : '+inttostr(l2)+' (han sido marcados)');
end;
procedure cascada(texto:string);
var
cadena : string;
begin
// Arrastra valor de celda superior a la celda que contiene TEXTO en cualquier parte
// Se inicia proceso desde el registro 2
writeln('Procesando cascada de valores...');l2:=0;
if tregistros<2 then exit;
if texto<>'0' then
for l1:=1 to tregistros-1 do
    begin
    cadena:='';
    for b1:=0 to no_campos-1 do
                             begin
                             if to_campos[b1].sel=1 then
                                                    begin
                                                    cadena:=tabla[l1].columna[b1];
                                                    // localizar el texto - si lo encontramos arrastramos valor
                                                    if (buscapos (texto,cadena,0)>0) then
                                                                                   begin
                                                                                   tabla[l1].columna[b1]:=tabla[l1-1].columna[b1];
                                                                                   inc(l2);
                                                                                   end;


                                                    end;
                             end;

    end;
if texto='0' then
for l1:=1 to tregistros-1 do
    begin
    cadena:='';
    for b1:=0 to no_campos-1 do
                             begin
                             if to_campos[b1].sel=1 then
                                                    begin
                                                    cadena:=tabla[l1].columna[b1];
                                                    // localizar vacias - si lo encontramos arrastramos valor
                                                    if cadena='' then
                                                                 begin
                                                                 tabla[l1].columna[b1]:=tabla[l1-1].columna[b1];
                                                                 inc(l2);
                                                                 end;


                                                    end;
                             end;

    end;
writeln;
writeln(' Registros en cascada procesados : '+inttostr(l2)+' (han sido marcados)');
end;
procedure borrar_marcados;
begin
//borrar los sobrantes
writeln('Borrando registros nulos...');
if tregistros=0 then exit;
l2:=tregistros;l1:=0;
repeat;
          if tabla[l1].tipo=1 then
                               begin
                               //eliminar sobrante
                               tabla[l1].tipo:=tabla[l2-1].tipo;
                               for b1:=0 to 512 do tabla[l1].columna[b1]:=tabla[l2-1].columna[b1];
                               dec(l2);dec(l1);
                               end;

inc(l1);
until l1>=l2;
tregistros:=l2;
writeln;
writeln(' Registros : '+inttostr(l2)+' resultantes');
end;

procedure dividir_columnas(columna,valordivisor: byte);
var
ncol,noc  : byte;
frase     : string;
pp1,pp2   : longint;
palabras  : array [0..512] of string;
tpalabras : word;

begin
//dividir una columna en varias
writeln('Dividiendo columna seleccionada...');
if tregistros=0 then exit;
l2:=tregistros;l1:=0;ncol:=0; noc:=no_campos;
repeat;

 // por cada registro se ve cuantas columnas son necesarias y se crean las que se necesiten
 // contamos el numero de palabras entre espacios

 frase:=tabla[l1].columna[columna];

 tpalabras:=0;

 for pp1:=0 to 512 do palabras[pp1]:='';

 for pp1:=1 to length(frase) do
     begin
     if (frase[pp1]<>chr(valordivisor)) then
                                        begin
                                        palabras[tpalabras]:=palabras[tpalabras]+frase[pp1]
                                        end
                                           else
                                           begin
                                           //nueva palabra
                                           inc(tpalabras);
                                           end;
     end;
 inc(tpalabras);

 // crear columnas necesarias y poner nuevos datos
 if ncol<tpalabras then
                   begin
                   //crear columnas nuevas
                   while(ncol<tpalabras)
                   do begin
                      to_campos[no_campos]:=to_campos[columna];
                      to_campos[no_campos].nombre:=to_campos[no_campos].nombre+inttostr(no_campos);
                      inc(ncol);
                      inc(no_campos);
                      end;
                   end;
 // llevar datos a nuevas columnas
 if tpalabras>0 then for pp2:=0 to tpalabras-1 do tabla[l1].columna[noc+pp2]:=palabras[pp2];

inc(l1);
until l1>=l2;
tregistros:=l2;
writeln;
writeln(' Registros : '+inttostr(l2)+' resultantes');
end;
function xvcampo(campo:string):byte;
var
sc1,sc2 : word;
begin
sc2:=999;
for sc1:=0 to no_campos-1 do if to_campos[sc1].nombre=campo then sc2:=sc1;
xvcampo:=sc2;
end;
function xvcampo2(campo:string):byte;
var
sc1,sc2 : word;
begin
sc2:=999;
for sc1:=0 to tcolumnas2-1 do if tabla2[0].columna[sc1]=campo then sc2:=sc1;
xvcampo2:=sc2;writeln(sc2,' >',tcolumnas2,'< ', campo, tabla2[0].columna[0], tabla2[0].columna[1]);
end;
procedure seleccionarcampos(campos:String);
var
sc1,sc2,sc3,sc4 : word;
scs1,scs2       : string;
begin
scs1:='';sc1:=1;
repeat;
scs1:=scs1+campos[sc1];
inc(Sc1);
if (campos[sc1]=',') or (sc1>length(campos)) then
                   begin
                   //ya tenemos un campo entero lo buscamos y seleccionamos
                   //existen dos posibilidades con @15,@16,operaciones,@


                   if scs1[1]<>'@'
                   then begin
                        // sin @
                        for sc2:=0 to no_campos-1 do if (buscapos(scs1,to_campos[sc2].nombre,0)>0) then to_campos[sc2].sel:=1;
                        end else
                             begin
                             // con @
                             sc3:=0;scs2:=scs1;scs2[1]:='0';
                             sc3:=strtoint(scs2);
                             to_campos[sc3].sel:=1;
                             end;

                   scs1:='';
                   inc(sc1);
                   end;
until sc1>length(campos);
end;
procedure seleccionarcampos_e(campos:String);
var
sc1,sc2,sc3,sc4 : word;
scs1,scs2       : string;
begin
scs1:='';sc1:=1;
repeat;
scs1:=scs1+campos[sc1];
inc(Sc1);
if (campos[sc1]=',') or (sc1>length(campos)) then
                   begin
                   //ya tenemos un campo entero lo buscamos y seleccionamos
                   //existen dos posibilidades con @15,@16,operaciones,@


                   if scs1[1]<>'@'
                   then begin
                        // sin @
                        for sc2:=0 to no_campos-1 do if scs1=to_campos[sc2].nombre then to_campos[sc2].sel:=1;
                        end else
                             begin
                             // con @
                             sc3:=0;scs2:=scs1;scs2[1]:='0';
                             sc3:=strtoint(scs2);
                             to_campos[sc3].sel:=1;
                             end;


                   scs1:='';
                   inc(sc1);
                   end;
until sc1>length(campos);
end;
procedure deseleccionarcampos(campos:String);
var
sc1,sc2,sc3,sc4 : word;
scs1,scs2       : string;
begin
scs1:='';sc1:=1;
repeat;
scs1:=scs1+campos[sc1];
inc(Sc1);
if (campos[sc1]=',') or (sc1>length(campos)) then
                   begin
                   //ya tenemos un campo entero lo buscamos y seleccionamos
                   for sc2:=0 to no_campos-1 do if to_campos[sc2].nombre=scs1 then to_campos[sc2].sel:=0;
                   scs1:='';
                   inc(sc1);
                   end;
until sc1>length(campos);
end;
function valcampo(campo:string):word;
var
sc1,sc2: word;
scs1,scs2 : string;
begin
sc1:=255;
for sc2:=0 to no_campos-1 do if to_campos[sc2].nombre=campo then sc1:=sc2;
result:=sc1;
end;
procedure cargar_archivo_af(fichero:string);
var
af1             : longint;
saf1,saf2,saf3  : string;
begin
//preparar campos estructura
//vaciar  - af1 es el tamaño por registro
no_campos:=0;af1:=0;
for b1:=0 to 512 do begin
                    to_campos[b1].nombre:='';
                    to_campos[b1].longitud:='';
                    to_campos[b1].sel:=0;
                    to_campos[b1].tipo:='';
                    to_campos[b1].formula:='';
                    end;
no_campos:=tregistros2;
writeln('Campos reconocidos: ',no_campos);
for b1:=0 to no_campos-1 do
                       begin
                       to_campos[b1].nombre:=tabla2[b1].columna[0];
                       tabla[0].columna[b1]:=tabla2[b1].columna[0];
                       to_campos[b1].longitud:=tabla2[b1].columna[1];
                       to_campos[b1].tipo:='texto';
                       af1:=af1+strtoint(tabla2[b1].columna[1]);
                       end;
writeln('Bytes por registro: ',af1);
//cargar datos
//vaciando memoria
if length(tabla)>0 then
for l1:=1 to length(tabla)-1 do for l2:=0 to 512 do
                       begin
                       tabla[l1].columna[l2]:='';
                       tabla[l1].tipo:=0;
                       end;

assignfile(archivo_origen,fichero);
reset(archivo_origen,1);
tregistros:=1;
setlength(bloque,filesize(archivo_origen)+1000);
blockread(archivo_origen,bloque[0],filesize(archivo_origen),l3);
closefile(archivo_origen);
l1:=0; //posicion
writeln('Longitud : '+inttostr(l3));
while (l1<l3) do
  begin
  // Si hay saltos de linea se ignoran
  if bloque[l1]=#13 then inc(l1);//saltar el retorno
  if bloque[l1]=#10 then inc(l1);//saltar el retorno
  //l2 es el contador de ancho b1 es el contador de campo l4 el de linea
  l2:=0;b1:=0;l4:=0;
  repeat;
  if l4<af1 then tabla[tregistros].columna[b1]:=tabla[tregistros].columna[b1]+bloque[l1];
  inc(l1);inc(l2);inc(l4);
  if l2>=strtoint(to_campos[b1].longitud) then
                                          begin
                                          //siguiente campo
                                          if b1<no_campos-1 then inc(b1);
                                          l2:=0;
                                          end;
  until (l1>=l3) or (bloque[l1]=#13) or (bloque[l1]=#10);
  // Si hay saltos de linea se ignoran
  if bloque[l1]=#13 then inc(l1);//saltar el retorno
  if bloque[l1]=#10 then inc(l1);//saltar el retorno
  //fin readln
  if l4>=af1 then inc(tregistros) else
                                  begin
                                  writeln('Registro ',tregistros,' no cumple las especificaciones. Posicion ',l1,' ancho ',l4,'.');
                                  for b2:=0 to no_campos-1 do tabla[tregistros].columna[b2]:=''; //borramos lo anterior
                                  end;
  if tregistros>=length(tabla) then begin
                                    setlength(tabla,tregistros+1000);
                                    writeln('Procesando [',tregistros,']');
                                    end;
  end;
writeln;
writeln('Cargados : '+inttostr(tregistros)+' registros');
writeln('Columnas : '+inttostr(no_campos));
tcolumnas:=no_campos;
writeln;writeln('Importación concluida.');
end;
procedure TMyApplication.DoRun;
var
  ErrorMsg: String;
begin
  // quick check parameters
  ErrorMsg:=CheckOptions('h','help');
  if ErrorMsg<>'' then begin
    ShowException(Exception.Create(ErrorMsg));
    Halt;
  end;

  // parse parameters
  if HasOption('h','help') then begin
    WriteHelp;
    Halt;
  end;

  { add your program here }
  is_campo:=0;
  setlength(tabla,1000);
  setlength(tabla2,1000);
  nombre_origen:='/';ichr:=9;schr:=9;
  nombre_destino:='/';
  //verificacion licencia
  fh_mes:=strtoint(FormatDateTime('mm',now));
  fh_ano:=strtoint(FormatDateTime('yyyy',now));
    if (fh_ano>licencia_ano) or ((fh_mes>licencia_mes) and (fh_ano=licencia_ano))
  then  fh_ano:=0 else  fh_ano:=1;
  if fh_ano=0 then
              begin
              //Licencia caducada
              writeln(verprogram);writeln;

              writeln(' Licencia de uso válida hasta: ',licencia_mes,'/',licencia_ano);
              writeln(' La licencia de este producto ha caducado.');
              writeln;
              writeln(' Contacte con Wasx Alpha Software. E-mail contacto: ruben.pastorv@gmail.com');
              readln;
              halt;
              end;

  if paramcount=0 then
  repeat;
  clrscr;

  writeln(verprogram);

  writeln(' Licencia de uso válida hasta: ',licencia_mes,'/',licencia_ano);

  writeln(' Cliente: ',cliente);
  writeln;
  writeln('  1. Definir origen            2. Definir destino');
  writeln('  3. Cargar tabla              4. Exportar tabla');
  writeln('  5. Mostrar registro          6. Mostrar columna');
  writeln('  7. Modificar estructura      8. Guardar configuracion');
  writeln('  9. Cargar configuracion     10. Seleccionar campo');
  writeln(' 11. Deseleccionar campo      12. Marcar registros duplicados');
  writeln(' 13. Cargar tabla auxiliar    14. Marcar reg coincidentes tabla-aux');
  writeln(' 15. Agregar tabla-aux        16. Ver tabla resultado');
  writeln(' 17. Fundir columnas          18. Agrupar registros por campos sel');
  writeln(' 19. Mostrar formulas         20. Crear nueva columna');
  writeln(' 21. Marcar reg nulos         22. Eliminar reg marcados');
  writeln(' 23. Selec. campos p nombre   24. Desel. campos nombre');
  writeln(' 25. Union de tabla-aux       26. Borrar espacios y filtrar {tab} y {CLRF}');
  writeln(' 27. Sustitución tabla-aux    28. Importar tabla ancho-fijo');
  writeln(' 29. Marcar reg campos nulos  30. Busca. copia y pega');
  writeln(' 31. Dividir columna          32. Filtrar caracteres');
  writeln(' 33. Marcar campos por clave  34. Exportar f.a.f');
  writeln(' 35. Marcar longitud reg      36. Intercambio T.AUX');
  writeln(' 37. Cascada por campo clave  38. Exportar SQL');

  writeln;
  write(' Archivo origen  : '+nombre_origen);writeln(' | Tabla auxiliar  : '+tabla_aux);
  writeln(' Archivo destino : '+nombre_destino);
  write(' Registros tabla principal : '+inttostr(tregistros)); writeln(' Registros tabla auxiliar : '+inttostr(tregistros2));
  write(' Columnas tabla principal  : '+inttostr(tcolumnas));writeln(' Columnas tabla auxiliar  : '+inttostr(tcolumnas2));
  if no_campos<>tcolumnas then writeln(' Comprobación    : ERROR EN CAMPOS');
  writeln;
  writeln(' Campos principales ( para desplazarnos + o - / mostrar todos *)');
  writeln(' ==================');

  if no_campos>0 then
                 begin
                 if no_campos>10 then b2:=10 else b2:=no_campos;

                 for b1:=0 to b2-1 do
                 begin
                 if to_campos[b1+is_campo].sel=0 then writeln('  '+inttostr(b1+is_campo)+' - '+to_campos[b1+is_campo].nombre+' tipo : '+to_campos[b1+is_campo].tipo+' tamaño/mod : '+to_campos[b1+is_campo].longitud);
                 if to_campos[b1+is_campo].sel=1 then writeln(' *'+inttostr(b1+is_campo)+' - '+to_campos[b1+is_campo].nombre+' tipo : '+to_campos[b1+is_campo].tipo+' tamaño/mod : '+to_campos[b1+is_campo].longitud);
                 end

                 end else
                     begin writeln(' ninguno'); end;
  writeln;
  writeln;
  writeln(' 0. terminar ');
  writeln;
  writeln;
  write('>');readln(comando);

  if comando = '+' then
                   begin
                   inc(is_campo,5);
                   comando:='';
                   end;

  if comando = '-' then
                   begin
                   if is_campo>5 then dec(is_campo,5) else is_campo:=0;
                   comando:='';
                   end;

  if comando = '*' then
                   begin
                   if no_campos>0 then
                   for b1:=0 to no_campos-1 do
                        begin
                        if to_campos[b1].sel=0 then writeln('  '+inttostr(b1)+' - '+to_campos[b1].nombre+' tipo : '+to_campos[b1].tipo+' tamaño/mod : '+to_campos[b1].longitud);
                        if to_campos[b1].sel=1 then writeln(' *'+inttostr(b1)+' - '+to_campos[b1].nombre+' tipo : '+to_campos[b1].tipo+' tamaño/mod : '+to_campos[b1].longitud);
                        end;
                   readln;
                   comando:='';
                   end;

  if comando = '1' then
                   begin
                   writeln('Definir origen:');
                   write('Archivo?');readln(nombre_origen);
                   nombre_destino:=nombre_origen+'.destino';
                   writeln;
                   writeln(' Ejemplo: 9 - tab / 59 - ;  ');
                   write('¿valor decimal de chr separador de columna? (pulsa <enter> para chr(9) tab)');readln(comando);
                   if comando<>'' then ichr:=strtoint(comando);
                   comando:='';
                   end;
                   
  if comando = '2' then
                   begin
                   writeln('Definir destino:');
                   write('Archivo?');readln(nombre_destino);
                   writeln;b1:=0;
                   writeln;
                   writeln(' Ejemplo: 9 - tab / 59 - ;  ');
                   write('¿valor decimal de chr separador de columna? (pulsa <enter> para chr(9) tab)');readln(comando);
                   if comando<>'' then schr:=strtoint(comando);
                   comando:='';
                   end;

  if comando = '3' then
                   begin
                   writeln;
                   if nombre_origen='/' then begin write('Archivo?');readln(nombre_origen);nombre_destino:=nombre_origen+'.destino'; end;
                   writeln;
                   write('¿Desea saltar a una posicion concreta dentro del fichero? (pulsa <enter> para cargar completo o indique la posición en caracteres)');readln(comando);
                   if comando<>'' then l5:=strtoint(comando) else l5:=0;
                   cargar_estructura(nombre_origen,l5);
                   writeln;
                   writeln;
                   cargar_registros_cvs(nombre_origen,l5);
                   writeln;
                   readln;
                   comando:='';
                   end;
                   
  if comando = '4' then
                   begin
                   write('Exportar registros 0 - todos 1 - marcados 2 - no marcados?');readln(l1);
                   l2:=1;
                   if l1>0 then begin write('Mantener primer registro 1 - sí ?');readln(l2);end;
                   exportar(l1,nombre_destino,l2);
                   comando:='';
                   end;
  if comando = '38' then
                   begin
                   write('Exportar registros 0 - todos 1 - marcados 2 - no marcados?');readln(l1);
                   exportar_sql(l1,nombre_destino);
                   comando:='';
                   end;

  if comando = '5' then
                   begin
                   writeln;
                   write('registro?');readln(l1);
                   mostrar_registro(l1);
                   writeln('Pulsa <enter> para continuar.');
                   readln;
                   comando:='';
                   end;

  if comando = '6' then
                   begin
                   writeln;
                   write('primer registro?');readln(l1);
                   write('ultimo registro?');readln(l2);
                   write('columna (0-512)?');readln(l3);
                   mostrar_columna(l1,l2,l3);
                   writeln('Pulsa <enter> para continuar.');
                   readln;
                   comando:='';
                   end;

  if comando = '7' then
                   begin
                   writeln;
                   write('campo (0-512 999 todos)?');readln(l1);
                   writeln('Tipo: ');  writeln;
                   writeln('0 - pasar por alto (la columna se anulará)');
                   writeln('1 - texto (contenido bruto)');
                   writeln('2 - numérico con decimales');
                   writeln('3 - supernumero (solo quedarán números con ceros a la izquierda /vg. 00000..X)');
                   writeln('4 - moneda (formato predeterminado EUROS) ');
                   writeln('5 - fcoma (numérico con decimales ajustados)');
                   writeln('6 - sql numérico (formato numérico decimal compatible con SQL SERVER)');
                   writeln('7 - superentero (formato similar a supernumero pero con signo / vg. +00000..X -00000..X');
                   writeln('8 - fecha ansi (fecha compatible formato ANSI con distintas variantes)');
                   writeln('9 - fecha (detecta la fecha de entrada y convierte a DD/MM/AAAA');
                   writeln('10 - fecha basada en dias transcurridos desde 01/01/1900');
                   writeln;
                   write('Seleccione tipo de datos:');readln(l2);
                   if l2>10 then l2:=0;
                   if l2>0 then
                   begin
                   // solo preguntar mas opciones si no es pasar por alto
                   writeln;
                   if l2=1 then writeln('*En formato texto rellena con espacios a la derecha.');
                   if l2=8 then begin
                                writeln('FORMATO ENTRADA VALIDO DD/MM/AAAA');
                                writeln('FORMATOS DE FECHA DE SALIDA:');
                                writeln('0 - AAAAMMDD');
                                writeln('1 - AAAAMM');
                                writeln('2 - AAAA');
                                writeln('3 - MM');
                                writeln('4 - DD');
                                writeln('5 - DDMMAAAA');
                                writeln('6 - MMAAAA');
                                end;
                  if l2=10 then begin
                                writeln('FORMATO ENTRADA basada 01/01/1900');
                                writeln('FORMATOS DE FECHA DE SALIDA:');
                                writeln('0 - AAAA/MM/DD');
                                writeln('1 - AAAA/MM');
                                writeln('2 - AAAA');
                                writeln('3 - MM');
                                writeln('4 - DD');
                                writeln('5 - DD/MM/AAAA');
                                writeln('6 - MM/AAAA');
                                end;
                   if l2=9 then begin
                                writeln('FORMATOS DE FECHA DE ENTRADA:');
                                writeln('1 - Automático');
                                writeln('2 - DD/MM/AAAA');
                                writeln('3 - AAAA/MM/DD');
                                writeln('4 - AAAA/DD/MM');
                                writeln('5 - MM/DD/AAAA');
                                writeln('6 - AAAAMMDD');
                                writeln('7 - AAAADDMM');
                                writeln('8 - DDMMAAAA');
                                writeln('9 - MMDDAAAA');
                                writeln;
                                writeln('FORMATO ENTRADA VALIDO DD/MM/AAAA');
                                writeln('FORMATOS DE FECHA DE SALIDA:');
                                writeln('0 - AAAA/MM/DD');
                                writeln('1 - AAAA/MM');
                                writeln('2 - AAAA');
                                writeln('3 - MM');
                                writeln('4 - DD');
                                writeln('5 - DD/MM/AAAA');
                                writeln('6 - MM/AAAA');
                                writeln;
                                writeln('Debe elegir ambos. Vg. 10');
                                writeln('Significa entrada automático y salida aaaa/mm/dd');
                                end;

                   writeln;
                   case l2 of
                   1: write('Tamaño : 0 - ilimitado. otro valor rellena?');
                   2: write('Precisión : 0 - ilimitado. otro valor rellena?');
                   3: write('Cifras : 0 - ilimitado. otro valor rellena?');
                   4: write('Decimales : 0 - ilimitado. otro valor rellena?');
                   5: write('Decimales : 0 - ilimitado. otro valor rellena?');
                   6: write('Precisión : 0 - ilimitado. otro valor rellena?');
                   7: write('Cifras : 0 - ilimitado. otro valor rellena?');
                   8: write('Formato de salida ?');
                   9: write('Formato de entrada y salida XY?');
                   10: write('Formato de salida ?');
                   end;
                   readln(l3);
                   end;
                   if l1=999 then
                   begin
                   for b1:=0 to no_campos-1 do
                   begin
                   if l3=0 then to_campos[b1].longitud:='ilimitado' else to_campos[b1].longitud:=inttostr(l3);
                   if l2=0 then to_campos[b1].tipo:='anular';
                   if l2=1 then to_campos[b1].tipo:='texto';
                   if l2=2 then to_campos[b1].tipo:='numerico';
                   if l2=3 then to_campos[b1].tipo:='supernumero';
                   if l2=4 then begin to_campos[b1].tipo:='moneda'; to_campos[b1].longitud:='2'; end;
                   if l2=5 then begin to_campos[b1].tipo:='fcoma'; end;
                   if l2=6 then begin to_campos[b1].tipo:='sql'; end;
                   if l2=7 then begin to_campos[b1].tipo:='superentero'; end;
                   if l2=8 then begin to_campos[b1].tipo:='fansi'; if to_campos[b1].longitud='ilimitado' then to_campos[b1].longitud:='0'; end;
                   if l2=9 then begin to_campos[b1].tipo:='fecha'; if to_campos[b1].longitud='ilimitado' then to_campos[b1].longitud:='0'; end;
                   if l2=10 then begin to_campos[b1].tipo:='f1900'; if to_campos[b1].longitud='ilimitado' then to_campos[b1].longitud:='0'; end;
                   end;
                   end else
                   begin
                   if l3=0 then to_campos[l1].longitud:='ilimitado' else to_campos[l1].longitud:=inttostr(l3);
                   if l2=0 then to_campos[l1].tipo:='anular';
                   if l2=1 then to_campos[l1].tipo:='texto';
                   if l2=2 then to_campos[l1].tipo:='numerico';
                   if l2=3 then to_campos[l1].tipo:='supernumero';
                   if l2=4 then begin to_campos[l1].tipo:='moneda'; to_campos[l1].longitud:='2'; end;
                   if l2=5 then begin to_campos[l1].tipo:='fcoma'; end;
                   if l2=6 then begin to_campos[l1].tipo:='sql'; end;
                   if l2=7 then begin to_campos[l1].tipo:='superentero'; end;
                   if l2=8 then begin to_campos[l1].tipo:='fansi'; if to_campos[l1].longitud='ilimitado' then to_campos[l1].longitud:='0';end;
                   if l2=9 then begin to_campos[l1].tipo:='fecha'; if to_campos[l1].longitud='ilimitado' then to_campos[l1].longitud:='0';end;
                   if l2=10 then begin to_campos[l1].tipo:='f1900'; if to_campos[l1].longitud='ilimitado' then to_campos[l1].longitud:='0';end;
                   if l2>0 then
                   begin
                   //solo mas opciones si no es anular
                   writeln(' Formula: (ejemplos)');
                   writeln;
                   writeln(' cadena : El campo contendrá una cadena de texto únicamente');
                   writeln(' {campo}cadena{campo} : El campo contendrá una concatenación de valor de campo seguido de un texto y luego otra vez valor del campo');
                   writeln(' {campo}+{campo2} : El campo contendrá el valor de la suma (siendo ambos numéricos da como resultado la suma)');
                   writeln(' {campo}+{campo2}+"1234" : El campo contendrá el valor de la suma (siendo dos campos numéricos y una constante (da como resultado la suma de todo)');
                   writeln;
                   writeln(' Operadores aritméticos : + (suma) - (resta) * (multiplicación) / (división)');
                   writeln(' Variables : $fecha$ (valor de fecha actual en formato DD/MM/AAAA)');
                   writeln(' Operadores lógicos : > (mayor) < (menor) = (igualdad)');
                   writeln(' Funciones : ');
                   writeln;
                   writeln(' $fecha$ : Devuelve valor de fecha actual en formato DD/MM/AAAA');
                   writeln(' @ : Devuelve valor de tamaño de los datos contenidos en la celda');
                   writeln(' % : Salta el siguiente caracter (si queremos meter unad dirección de email será por ejemplo nombre%@dominio.com)');
                   writeln;
                   //otras funciones:
// $variable$ - funciones definidas
// > - mayor que
// < - menor que
// = - igual que
// @ - longitud cadena
// # - Fecha AAAAMMDD (formato ASNI)
// % - Salta siguiente
                   write('formula (Pulse enter para omitir)?');readln(comando);
                   to_campos[l1].formula:=comando;
                   write('nuevo nombre campo (Pulse enter para omitir)?');readln(comando);
                   to_campos[l1].nnombre:=comando;
                   end;
                   end;
                   comando:='';
                   end;
  if comando = '8' then
                   begin
                   //guardar
                   writeln;
                   write('nombre configuracion?');readln(comando);
                   guardar(comando);
                   comando:='';
                   end;
  if comando = '9' then
                   begin
                   //cargar
                   writeln;
                   write('nombre configuracion?');readln(comando);
                   cargar(comando);
                   comando:='';
                   end;
  if comando = '10' then
                   begin
                   //seleccionar
                   writeln;
                   write('seleccionar campo (0-512)?');readln(l1);
                   to_campos[l1].sel:=1;
                   comando:='';
                   end;
  if comando = '11' then
                   begin
                   //deseleccionar
                   writeln;
                   write('deseleccionar campo (0-512)?');readln(l1);
                   to_campos[l1].sel:=0;
                   comando:='';
                   end;
  if comando = '12' then
                   begin
                   //duplicados
                   write('Marcar registros duplicados 0- todos 1 - solo duplicados ?');readln(l1);
                   writeln;
                   mostrar_duplicados(l1);
                   writeln;
                   writeln('Pulsa <enter> para continuar.');
                   readln;
                   comando:='';
                   end;
  if comando = '13' then
                   begin
                   //cargar t aux
                   writeln;
                   write('nombre tabla auxiliar?');readln(comando);tabla_aux:=comando;
                   cargar_registros_cvs_auxiliar(comando);
                   writeln;
                   readln;
                   comando:='';
                   end;
  if comando = '14' then
                   begin
                   //coincidentes
                   writeln;
                   marcar_coincidentes;
                   writeln;
                   writeln('Pulsa <enter> para continuar.');
                   readln;
                   comando:='';
                   end;

  if comando = '15' then
                   begin
                   //agregar
                   writeln;
                   write('Agregar registros desde posicion 0- todos ?');readln(l1);
                   writeln;
                   agregar_aux(l1);
                   writeln;
                   writeln('Pulsa <enter> para continuar.');
                   readln;
                   comando:='';
                   end;
  if comando = '16' then
                   begin
                   //ver tabla resultado
                   write('Ver registros 0 - todos 1 - marcados 2 - no marcados?');readln(l1);
                   l2:=1;
                   if l1>0 then begin write('Mantener primer registro 1 - sí ?');readln(l2);end;
                   b1:=schr;schr:=9; exportar(l1,'temporal.cvs',l2); schr:=b1;
                   executeprocess('visorcvs.exe','temporal.cvs');
                   comando:='';
                   end;
    if comando = '17' then
                   begin
                   //fundir columnas
                   writeln('IMPORTANTE NO modifica información, solo la estructura de la tabla.');
                   write('Columna destino (0-512)?');readln(l1);
                   if l1>0 then begin write('Mantener primer registro 1 - sí ?');readln(l2);end;
                   write('Columna A(0-512)?');readln(l3);
                   write('Columna B(0-512)?');readln(l4);
                   //operaciones
                   to_campos[l1].formula:='{'+to_campos[l3].nombre+'}{'+to_campos[l4].nombre+'}';
                   to_campos[l3].tipo:='anular';
                   to_campos[l4].tipo:='anular';
                   exportar(0,'temporal.cvs',l2);
                   //endoperaciones
                   writeln;
                   cargar_estructura('temporal.cvs',0);
                   writeln;
                   cargar_registros_cvs('temporal.cvs',0);
                   writeln;
                   comando:='';
                   end;
    if comando = '18' then
                   begin
                   //agrupar
                   writeln('Función: Suma registros sumando valores de columna');
                   write('Columna suma (0-512)?');readln(l1);
                   agrupar_duplicados(l1);
                   writeln;
                   writeln('Pulsa <enter> para continuar.');
                   readln;
                   comando:='';
                   end;
    if comando = '19' then
                   begin
                   //campos
                   writeln('Funciones de campos:');
                   if no_campos>0 then
                   for b1:=0 to no_campos-1 do writeln(inttostr(b1)+' : '+to_campos[b1].formula);
                   writeln;
                   writeln('Pulsa <enter> para continuar.');
                   readln;
                   comando:='';
                   end;
    if comando = '20' then
                   begin
                   // crear campo, por defecto texto ilimitado
                   write('Nombre campo?');readln(comando);
                   to_campos[no_campos].nombre:=comando;
                   to_campos[no_campos].longitud:='ilimitado';
                   to_campos[no_campos].tipo:='texto';
                   inc(no_campos);inc(tcolumnas);
                   writeln('Campo creado!');
                   writeln;
                   write('Rellenar celda: 1 - valor repetido 2 - incremental 0 - nada?');readln(l1);
                   if l1=1 then
                           begin
                           writeln('NOTA! Ciertos caracteres son incompatibles');
                           write('valor?');readln(comando);
                           if tregistros>0 then
                           for l2:=0 to tregistros-1 do tabla[l2].columna[no_campos-1]:=comando;
                           end;
                           
                   if l1=2 then
                           begin
                           if tregistros>0 then
                           for l2:=0 to tregistros-1 do tabla[l2].columna[no_campos-1]:=inttostr(l2);
                           end;
                   comando:='';
                   end;
       if comando = '21' then
                   begin
                   //marcar nulos
                   marcar_nulos;
                   writeln;
                   writeln('Pulsa <enter> para continuar.');
                   readln;
                   comando:='';
                   end;
       if comando = '22' then
                   begin
                   //borrar marcados
                   borrar_marcados;
                   writeln;
                   writeln('Pulsa <enter> para continuar.');
                   readln;
                   comando:='';
                   end;
       if comando = '23' then
                   begin
                   //seleccionar campos
                   write('seleccionar campos (separados por coma) (acepta @nºcolumna ejm @0,@3,@5...)?');readln(comando);
                   seleccionarcampos(comando);
                   comando:='';
                   end;
       if comando = '24' then
                   begin
                   //deseleccionar campos
                   write('deseleccionar campos (separados por coma)?');readln(comando);
                   deseleccionarcampos(comando);
                   comando:='';
                   end;
       if comando = '25' then
                   begin
                   //unir tablas
                   union_taux;
                   readln;
                   comando:='';
                   end;
       if comando = '26' then
                   begin
                   //borrar espacios
                   filtrarchr(0,32);
                   filtrarchr(9,32);
                   filtrarchr(13,32);
                   filtrarchr(10,32);
                   write('Borrar los espacios: 0- solo finales 1- Todos ');readln(b1);
                   if b1=1 then borrar_tespacios;
                   borrar_espacios;
                   readln;
                   comando:='';
                   end;
       if comando = '27' then
                   begin
                   //Sustitucion
                   writeln('Función: Sustitución de valores por Tabla-aux.');
                   writeln('Atención: Marca los registros de modificados!');
                   writeln('Info adicional: Sustituye si coinciden campos sel.');
                   write('Columna destino (0-512)?');readln(l1);
                   ss_taux(l1);
                   writeln;
                   writeln('Pulsa <enter> para continuar.');
                   readln;
                   comando:='';
                   end;
         if comando = '28' then
                   begin
                   //archivo ancho-fijo
                   writeln('Importación de archivo de ancho-fijo:');
                   writeln;
                   writeln('NOTA! Se cargará una tabla con las especificaciones');
                   writeln('en la tabla auxiliar.');
                   writeln;
                   write('Archivo de especifiaciones?');readln(comando);tabla_aux:=comando;
                   cargar_registros_cvs_auxiliar(comando);
                   write('Archivo de archo-fijo a importar?');readln(comando);
                   cargar_archivo_af(comando);
                   readln;
                   comando:='';
                   end;
         if comando = '29' then
                   begin
                   //marcar reg campos nulos
                   marcar_camposnulos;
                   writeln;
                   writeln('Pulsa <enter> para continuar.');
                   readln;
                   comando:='';
                   end;
         if comando = '30' then
                   begin
                   //busca copia y pega
                   writeln('Busca - copia y pega:');
                   writeln;
                   writeln('Busca en tabla auxiliar por columna seleccionada.');
                   writeln('Sustituye en tabla principal el valor del campo destino');
                   writeln('por la porción de texto deseada de la auxiliar.');
                   writeln;
                   writeln('***Requiere:Tabla auxiliar de una sola columna.***');
                   writeln;
                   writeln('Atención: Marca los registros modificados!');
                   writeln('Info adicional: Sustituye si coinciden campos sel.');
                   writeln;
                   write('Columna destino (0-512)?');readln(l1);
                   ssporcion_taux(l1);
                   writeln;
                   writeln('Pulsa <enter> para continuar.');
                   readln;
                   comando:='';
                   end;
         if comando = '31' then
                   begin
                   //busca copia y pega
                   writeln('Dividir campo en otros nuevos:');
                   writeln;
                   writeln('Divide los campos en tantos como sean necesarios.');
                   writeln('Cada nueva columna contendrá una palabra o cifra.');
                   writeln('El caracter de division es el codigo decimal. 32 - espacio');
                   writeln;
                   writeln;
                   write('Campo a dividir (0-512)?');readln(l1);
                   write('Valor decimal del caracter separador ?');readln(l2);
                   dividir_columnas(l1,l2);
                   writeln;
                   writeln('Pulsa <enter> para continuar.');
                   readln;
                   comando:='';
                   end;
         if comando = '32' then
                   begin
                   //filtrar caracteres
                   writeln('Filtrar chr:');
                   writeln;
                   writeln('Filtra todos los campos para evitar caracteres determinados.');
                   writeln('Sustituye el caracter buscado por el deseado. Trabaja en tabla principal.');
                   writeln;
                   writeln;
                   write('Escriba el codigo ascii del caracter a cambiar?');readln(l1);
                   write('Escriba el codigo ascii del caracter nuevo?');readln(l2);
                   writeln;
                   writeln('Sustituyendo chr "'+chr(l1)+'" por chr "'+chr(l2)+'"');
                   writeln;
                   filtrarchr(l1,l2);
                   writeln;
                   writeln('Pulsa <enter> para continuar.');
                   readln;
                   comando:='';
                   end;
         if comando = '33' then
                   begin
                   //filtrar caracteres
                   writeln('Marcar registros por campo con clave:');
                   writeln;
                   writeln('Selecciona los registros en los que el campo/s seleccionado/s contenga/n cierta cadena o valor.');
                   writeln('Solo marca el registro. No diferencia entre campos numéricos o de texto.');
                   writeln;
                   writeln('Elija la función: 0 - clave 1 - "mayor que" 2 - "menor que"');
                   readln(l1);
                   if l1=0 then write('Escriba la cadena a utilizar de clave:');
                   if l1=1 then write('Marcar registros con valor en campo mayor que:');
                   if l1=2 then write('Marcar registros con valor en campo menor que:');

                   readln(comando);
                   writeln;
                   writeln;
                   if l1=0 then filtrarcad(comando);
                   if l1=1 then fmayorque(comando);
                   if l1=2 then fmenorque(comando);
                   writeln;
                   writeln('Pulsa <enter> para continuar.');
                   readln;
                   comando:='';
                   end;
         if comando = '34' then
                   begin
                   writeln('Exportación de ficheros de ancho fijo:');
                   writeln;
                   writeln;
                   writeln('Debe cargar un fichero en tabla auxiliar con las especificaciones.');
                   writeln('El fichero ?');
                   write  ('Exportar registros 0 - todos 1 - marcados 2 - no marcados?');readln(l1);
                   l2:=1;
                   if l1>0 then begin write('Mantener primer registro 1 - sí ?');readln(l2);end;
                   exportar_af(l1,nombre_destino,l2);
                   end;
         if comando = '35' then
                   begin
                   writeln('Localizar registros con exceso de longitud:');
                   writeln;
                   writeln;
                   writeln('Logitud de corte ? (valor numerico máximo 65535)');readln(l1);
                   localizarexcesolongitud(l1);
                   writeln;
                   writeln('Pulsa <enter> para continuar.');
                   readln;
                   comando:='';
                   end;
         if comando = '36' then
                   begin
                   //Intercambio
                   writeln('Función: Intercambio de valores por Tabla-aux.');
                   writeln('Atención: Marca los registros de modificados!');
                   writeln('Info adicional: intercambia el valor cuando coincide');
                   write('Campo de TPRINCIPAL clave que recibirá el valor?');readln(comando);l1:=xvcampo(comando);
                   write('Campo de TAUX con valor que reemplazará columna clave?');readln(comando);l2:=xvcampo2(comando);
                   ssi_taux(l1,l2);
                   writeln;
                   writeln('Pulsa <enter> para continuar.');
                   readln;
                   comando:='';
                   end;
         if comando = '37' then
                   begin
                   //Intercambio
                   writeln('Función: Cascada de valores de celda superior cuando contenga un texto determinado.');
                   writeln('Informacion: Afecta solo a los campos seleccionados. ***Escriba un 0 (cero) si quiere valores nulos***');
                   writeln;
                   write('Texto a buscar para aplicar cascada?');readln(comando);
                   cascada(comando);
                   writeln;
                   writeln('Pulsa <enter> para continuar.');
                   readln;
                   comando:='';
                   end;
  until comando = '0';
  // proceso automatico
  if paramcount>0 then
  begin
  writeln('Procedimiento por parámetros...');
  operacion:=paramstr(1);
  if operacion<>'cvaf'
  then
  begin
  // **** operaciones comunes si no es cvaf
  xx1:=paramstr(2);//campos de seleccion
  xx2:=paramstr(3);//campo de operacion
  // vemos separador de campos de entrada
  if paramstr(9)<>'' then ichr:=strtoint(paramstr(9)) else ichr:=9;
  nombre_origen:=paramstr(4);
  tabla_aux:=paramstr(5);
  nombre_especf:=paramstr(6);
  //cargar tabla principal
  if operacion='utf8' then esutf8:=true else esutf8:=false;

  if operacion='saltcad' then
                         begin
                         l5:=determinarsalto(nombre_origen,xx2);
                         cargar_estructura(nombre_origen,l5);writeln;
                         cargar_registros_cvs(nombre_origen,l5);writeln;
                         end;

  if operacion='saltar' then
                        begin
                        cargar_estructura(nombre_origen,strtoint(xx2));writeln;
                        cargar_registros_cvs(nombre_origen,strtoint(xx2));writeln;
                        end;

  if (operacion<>'saltar') and (operacion<>'saltcad') then
                        begin
                        cargar_estructura(nombre_origen,0);writeln;
                        cargar_registros_cvs(nombre_origen,0);writeln;
                        end;
  //cargar especificaciones
  if nombre_especf<>'0' then cargar(nombre_especf) else writeln('ATENCION: NO SE CARGAN ESPECIFICACIONES.');
  writeln;
  nombre_destino:=paramstr(7);
  //cargar tabla auxiliar
  if tabla_aux<>'0' then cargar_registros_cvs_auxiliar(tabla_aux) else writeln('ATENCION: NO SE CARGA TABLA AUXILIAR.');
  writeln;
  //marcar campos de selección
  if operacion<>'filtrar' then seleccionarcampos_e(xx1); // selecciona campos pero estricto
  //efectuar operacion y exportar
  excampos:=1;
  if paramstr(8)<>'' then excampos:=strtoint(paramstr(8));

  // separador de campos de salida
  if paramstr(10)<>'' then schr:=strtoint(paramstr(10)) else schr:=9;
  // **** fin operaciones comunes
  end else
      begin
      //solo para cvaf
      nombre_origen:=paramstr(2);
      tabla_aux:=paramstr(3); //especificaciones ancho fijo
      nombre_especf:=paramstr(5); //formato de salida
      if paramstr(6)='0' then excampos:=0;
      if paramstr(6)='1' then excampos:=1;
      if paramstr(7)<>'' then schr:=strtoint(paramstr(7)) else schr:=9;
      //primeros procesos de cvaf
      cargar_registros_cvs_auxiliar(tabla_aux);
      cargar_archivo_af(nombre_origen);
      //cargar especificaciones
      for b1:=0 to no_campos-1 do to_campos[b1].longitud:='ilimitado';
      if nombre_especf<>'0' then cargar(nombre_especf);
      nombre_destino:=paramstr(4);
      end;

  if operacion='agrupar' then
                          begin
                          agrupar_duplicados(valcampo(xx2));
                          exportar(0,nombre_destino,excampos);
                          end;
  if operacion='nocoincidentes' then
                          begin
                          marcar_coincidentes;
                          exportar(2,nombre_destino,excampos);
                          end;

  if operacion='coincidentes' then
                          begin
                          marcar_coincidentes;
                          exportar(1,nombre_destino,excampos);
                          end;
  if operacion='agregar' then
                          begin
                          agregar_aux(strtoint(xx2));
                          exportar(0,nombre_destino,excampos);
                          end;
  if operacion='cvaf' then
                          begin
                          //antes de exportar hacemos correcciones
                          filtrarchr($22,$20);
                          borrar_espacios;
                          exportar(0,nombre_destino,excampos);
                          end;
  if operacion='bespacios' then
                           begin
                           //antes de exportar borramos los espacios y correcciones
                           filtrarchr(0,32);
                           filtrarchr(9,32);
                           filtrarchr(13,32);
                           filtrarchr(10,32);
                           borrar_espacios;
                           exportar(0,nombre_destino,excampos);
                           end;
  if operacion='limpiar' then
                           begin
                           //antes de exportar borramos los espacios y correcciones
                           filtrarchr(0,32); // NULL
                           filtrarchr(9,32); // TAB
                           filtrarchr(13,32);// CR
                           filtrarchr(10,32);// LF
                           filtrarchr(34,32);// "
                           filtrarchr(39,32);// '
                           filtrarchr(42,32);// *
                           filtrarchr(58,32);// :
                           filtrarchr(60,32);// <
                           filtrarchr(62,32);// >
                           filtrarchr(38,32);// &
                           filtrarchr(40,32);// (
                           filtrarchr(41,32);// )
                           filtrarchr(35,32);// #
                           filtrarchr(26,32);// 1A 26 sub

                           borrar_tespacios;
                           borrar_espacios;
                           exportar(0,nombre_destino,excampos);
                           end;
  if operacion='limpiar_old' then
                           begin
                           //compatibilidad con procesadores viejos
                           borrar_tespacios;
                           borrar_espacios;
                           exportar(0,nombre_destino,excampos);
                           end;
  if operacion='sustitucion' then
                           begin
                           ss_taux(xvcampo(xx2));
                           exportar(0,nombre_destino,excampos);
                           end;
  if operacion='intercambio' then
                           begin
                           ssi_taux(xvcampo(xx1),xvcampo2(xx2));
                           exportar(0,nombre_destino,excampos);
                           end;
  if operacion='union' then
                           begin
                           union_taux;
                           exportar(0,nombre_destino,excampos);
                           end;
  if operacion='dividircolumns' then
                           begin
                           dividir_columnas(xvcampo(xx2),strtoint(xx1));
                           exportar(0,nombre_destino,excampos);
                           end;
  if operacion='stcbusqueda' then
                           begin
                           ssporcion_taux(xvcampo(xx2));
                           exportar(0,nombre_destino,excampos);
                           end;
  if operacion='filtrar' then
                           begin
                           filtrarchr(strtoint(xx1),strtoint(xx2));
                           exportar(0,nombre_destino,excampos);
                           end;
  if operacion='buscar' then
                           begin
                           filtrarcad(xx2);
                           exportar(1,nombre_destino,excampos);
                           end;
  if operacion='excluir' then
                           begin
                           filtrarcad(xx2);
                           exportar(2,nombre_destino,excampos);
                           end;
  if operacion='mayor' then
                           begin
                           fmayorque(xx2);
                           exportar(1,nombre_destino,excampos);
                           end;
  if operacion='menor' then
                           begin
                           fmenorque(xx2);
                           exportar(1,nombre_destino,excampos);
                           end;
  if operacion='noduplicados' then
                           begin
                           mostrar_duplicados(1);
                           borrar_marcados;
                           marcar_nulos;
                           borrar_marcados;
                           exportar(0,nombre_destino,excampos);
                           end;
  if operacion='noregcnulos' then
                           begin
                           marcar_camposnulos;
                           borrar_marcados;
                           exportar(0,nombre_destino,excampos);
                           end;
  if operacion='regcnulos' then
                           begin
                           marcar_camposnulos;
                           exportar(1,nombre_destino,excampos);
                           end;
  if operacion='formato' then
                           begin
                           exportar(0,nombre_destino,excampos);
                           end;
  if operacion='utf8' then
                           begin
                           exportar(0,nombre_destino,excampos);
                           end;
  if operacion='saltar' then
                           begin
                           exportar(0,nombre_destino,excampos);
                           end;
  if operacion='saltcad' then
                           begin
                           exportar(0,nombre_destino,excampos);
                           end;
  if operacion='expaf' then
                           begin
                           exportar_af(0,nombre_destino,excampos);
                           end;
  if operacion='exsql' then
                           begin
                           exportar_sql(0,nombre_destino);
                           end;
  if operacion='cascada' then
                           begin
                           cascada(xx2);
                           exportar(0,nombre_destino,excampos);
                           end;

  end;
  writeln('Operación concluida');
  // stop program loop
  Terminate;
end;

constructor TMyApplication.Create(TheOwner: TComponent);
begin
  inherited Create(TheOwner);
  StopOnException:=True;
end;

destructor TMyApplication.Destroy;
begin
  inherited Destroy;
end;

procedure TMyApplication.WriteHelp;
begin
  writeln(verprogram);
  writeln;
  writeln(' Funciones por linea de comandos:');
  writeln;
  writeln(' edatco comando {xx1,..} {xx2} {origen} {auxiliar} {formato} {destino} {xx3} {xx4} {xx5}');
  writeln;
  writeln(' [comando]: funciones automáticas ');
  writeln;
  writeln(' agrupar        -> Agrupa coincidentes por campos [xx1] y sumando [xx2].');
  writeln(' nocoincidentes -> Registros no coincidentes con tabla auxiliar.');
  writeln(' coincidentes   -> Registros coincidentes con tabla auxiliar.');
  writeln(' agregar        -> Agrega los registros de la T.Aux desde posicion [xx2].');
  writeln(' cvaf           -> (*)convertir tabla ancho-fijo con formato con especificaciones [xx2].');
  writeln(' bespacios      -> Borrar espacios finales y filtra caracteres {tab} y {cl/rf}.');
  writeln(' limpiar        -> Conjunto de operaciones específicas para limpiar campos.');
  writeln(' union          -> Union de tabla principal y auxiliar por campo [xx1] coincidentes.');
  writeln(' sustitucion    -> Sustituir campo [xx2] por [xx1] coincidentes con T.Aux.');
  writeln(' intercambio    -> Intercambio campo [xx1] por [xx2] con origen en T.Aux.');
  writeln(' stcbusqueda    -> Sustituir campo [xx2] por [xx1] coincidentes con T.Aux.');
  writeln(' noduplicados   -> Elimina los registros duplicados sobrantes y los nulos.');
  writeln(' noregcnulos    -> Elimina los registros con los campos [xx1] nulos.');
  writeln(' regcnulos      -> Registros con los campos [xx1] nulos');
  writeln(' dividircolumns -> Divide columnas [xx2] con separador [xx1] en nuevas columnas.');
  writeln(' filtrar        -> filtrar campos sustituyendo caracter [xx1] por [xx2] en codigo ascii.');
  writeln(' buscar         -> Registros donde campos [xx1] contengan [xx2].');
  writeln(' excluir        -> Registros donde campos [xx1] no contengan [xx2].');
  writeln(' mayor          -> Registros donde campos [xx1] contenga valor mayor que [xx2].');
  writeln(' menor          -> Registros donde campos [xx1] contenga valor menor que [xx2].');
  writeln(' formato        -> No efectúa operaciones sobre registros. solo aplica formato.');
  writeln(' utf8           -> Solo aplica formato y convierte en ansi.');
  writeln(' expaf          -> Exportar ancho fijo. T.aux contiene orden de salida.');
  writeln(' exsql          -> Exportar como fichero SQL.');
  writeln(' cascada        -> Cascada de valores de campo seleccionado que contenga [xx2].');
  writeln(' saltar         -> Carga fichero principal desde posición [xx2] a nivel byte.');
  writeln(' saltcad        -> Carga fichero principal desde la cadena [xx2] saltandose datos previos.');
  writeln;
  writeln(' (*) Ejemplo: edatco cvaf origen.txt espec_anchofijo.sp destino.txt formato.st 0');
  writeln(' El comando cvaf es especial y modifica el número y orden de parámetros.');
  writeln(' El formato de salida (formato.st) es opcional. Valor 0 para no cargar formato.');
  writeln;
  writeln(' Modificadores y parámetros adicionales:');
  writeln(' xx1,.. campos a seleccionar separados por coma Ej. nombre,apellidos,etc.');
  writeln('        NOTA: pueden ser nombre de campos o nº columna anteponiendo @.');
  writeln('        ejemplo: edatco @0,@1,@2 ... selecciona las tres primeras columnas. ');
  writeln(' xx2    valor auxiliar para otras operaciones (suele ser un campo).');
  writeln(' xx3    Nº de filas a saltar en la exportacion (0 ninguna, 1 o más). Es opcional.');
  writeln(' xx4    Chr de separacion columnas para ficheros de entrada. Por defecto chr(9) Tab.');
  writeln(' xx5    Chr de separacion columnas para ficheros de salida. Por defecto chr(9) Tab.');
  writeln;
  writeln(' Ejemplo:    edatco comando 0 0 nombres.txt nombres2.txt formatosalida.st resultado.txt 1');
  writeln;
  writeln(' "resultado.txt" contendrá los datos resultantes de aplicar el formato de salida a los datos');
  writeln('                 contenidos en el archivo "nombres.txt".');

end;

var
  Application: TMyApplication;

{$R *.res}

begin
  Application:=TMyApplication.Create(nil);
  Application.Title:='edatco';
  Application.Run;
  Application.Free;
end.

