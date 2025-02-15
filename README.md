Ниже приведу код, используемый на стороне мобильного приложения

1. Документ "Доставка"

   * Форма документа
    ![image](https://github.com/user-attachments/assets/c3277e23-b91b-486c-a3d8-a469f77dc9ba)

<details>
 <summary> Модуль формы документа, в котором реализовано возможность создать фото с помощью камеры мобильного устройстваи вывести его на форму, также при открытии формы в реквизит НомерТелефона записывается номер из Справочника Контрагенты, а также реализована команда позвонить </summary>

```bsl
//Добавьте в документ «Доставка» реквизит «Фото», реализуйте возможность создать фото 
//с помощью камеры мобильного устройства и вывести его на форму   

&НаКлиенте
Процедура АдресФотоНажатие(Элемент, СтандартнаяОбработка)
	
	#Если МобильноеПриложениеКлиент Тогда
		
		//отключаем стандартную обработку, ткт стандартное действие 
		//для обработки нажатия на строку - вывести её содержимое в предупреждение, нам это не нужно
		СтандартнаяОбработка = Ложь;
		
		Если Не СредстваМультимедиа.ПоддерживаетсяФотоснимок() Тогда
			Возврат;
		КонецЕсли;
		
		Данные = СредстваМультимедиа.СделатьФотоснимок();
		
		Если Данные = Неопределено Тогда
			Возврат;
		КонецЕсли;
		
		АдресФото = ПоместитьВоВременноеХранилище(Данные.ПолучитьДвоичныеДанные(), УникальныйИдентификатор);
		
	#КонецЕсли
	
КонецПроцедуры

&НаСервере
Процедура ПередЗаписьюНаСервере(Отказ, ТекущийОбъект, ПараметрыЗаписи)
	//сохраним картинку в хранилище значения и сохраним в реквизит фотографию
	Если ЗначениеЗаполнено(АдресФото) Тогда
		//получим двоичные данные фото
		ДвоичныеДанныеФото = ПолучитьИзВременногоХранилища(АдресФото);
		ДанныеВХранилище = Новый ХранилищеЗначения (ДвоичныеДанныеФото);
		ТекущийОбъект.Фото = ДанныеВХранилище;
	КонецЕсли;
КонецПроцедуры

&НаСервере
Процедура ПриЧтенииНаСервере(ТекущийОбъект)
	// при открытии наобходимо получить фото поместить ее во временное хранилище и заполнить реквизит формы
	ДвоичныеДанныеФото = ТекущийОбъект.Фото.Получить();
	АдресФото = ПоместитьВоВременноеХранилище(ДвоичныеДанныеФото, УникальныйИдентификатор); 
	
	//получение номера телефона контрагента из Справочника
	Запрос = Новый Запрос;
	Запрос.Текст = "ВЫБРАТЬ
	               |	Контрагенты.НомерТелефона КАК НомерТелефона
	               |ИЗ
	               |	Справочник.Контрагенты КАК Контрагенты
	               |ГДЕ
	               |	Контрагенты.Ссылка = &Ссылка"; 
	Запрос.УстановитьПараметр("Ссылка", Объект.Контрагент);
	
	Выборка = Запрос.Выполнить().Выгрузить();
	
	Объект.НомерТелефона = Выборка[0].НомерТелефона;
КонецПроцедуры

&НаКлиенте
Процедура Позвонить(Команда)
	#Если МобильноеПриложениеКлиент Тогда
		
		Если ЗначениеЗаполнено(Объект.НомерТелефона)Тогда
			СредстваТелефонии.НабратьНомер(Объект.НомерТелефона, Ложь);
		Иначе
			Сообщение = Новый СообщениеПользователю;
			Сообщение.Текст = "Не указан номер телефона";
			Сообщение.Поле = "НомерТелефона";
			Сообщение.Сообщить();
		КонецЕсли;
		
	#КонецЕсли
КонецПроцедуры
 ```

</details>

<details>
 <summary> Модуль объекта документа, в котором реализована проверка заполненности реквизитов - при выборе статуса "Отклонен курьером" или "Отклонен клиентом" система требует заполнить комментарий, а также регистрация документов "Доставка" при записи </summary>
    
```bsl
Процедура ОбработкаПроверкиЗаполнения(Отказ, ПроверяемыеРеквизиты)
	
	//При выборе статуса «Отклонён курьером» или «Отклонён клиентом» 
	//система должна требовать заполнить комментарий   
	//проверяемые реквизиты - массив - у меня это реквизит Статус и Комментарий
	
	НепроверяемыеРеквизиты = Новый Массив();
	
	//если Статус не отклонен то дабавим в массив непроверяемых реквизитов остальыне статусы и комментарий
	Если Статус = Перечисления.СтатусыДоставок.ВзятВРаботу 
		или Статус = Перечисления.СтатусыДоставок.Выполнен
		или Статус = Перечисления.СтатусыДоставок.Запланирован Тогда  
		НепроверяемыеРеквизиты.Добавить("ВзятВРаботу");
		НепроверяемыеРеквизиты.Добавить("Выполнен");
		НепроверяемыеРеквизиты.Добавить("Запланирован");
		НепроверяемыеРеквизиты.Добавить("Комментарий");
		
		//если статус Отклонен то проверим заполненность поля Комментарий
	ИначеЕсли Не ЗначениеЗаполнено(Комментарий) Тогда
		
		ИндексКомментарий = ПроверяемыеРеквизиты.Найти("Комментарий");
		
		// Если он не заполнен, сообщим об этом пользователю
		Сообщение = Новый СообщениеПользователю();
		Сообщение.Текст = "Заполните поле комментарий";
		Сообщение.Поле = "Комментарий";
		Сообщение.УстановитьДанные(ЭтотОбъект);
		
		Сообщение.Сообщить();
		
		// Сообщим платформе, что мы сами обработали проверку заполнения реквизита "Комментарий"
		ПроверяемыеРеквизиты.Удалить(ИндексКомментарий);
		
		// Так как информация не консистентна, то продолжать работу дальше смысла нет
		
		Отказ = Истина;
		
	КонецЕсли;

	//вызвать процедуру для удаления непроверяемых реквизитов
	ОбщегоНазначения.УдалитьНепроверяемыеРеквизитыИзМассива(ПроверяемыеРеквизиты, НепроверяемыеРеквизиты);  
	
КонецПроцедуры;

#Если МобильноеПриложениеКлиент Тогда
Процедура ПередЗаписью(Отказ, РежимЗаписи, РежимПроведения)
	// реализовать регистрацию документов «Доставка» при записи
	
	Если ОбменДанными.Загрузка Тогда
		Возврат;
	КонецЕсли;
	
	Запрос = Новый Запрос;
	Запрос.Текст = " ВЫБРАТЬ
	                |	ОбменСМобильнымПриложением.Ссылка КАК Ссылка
	                |ИЗ
	                |	ПланОбмена.ОбменСМобильнымПриложением КАК ОбменСМобильнымПриложением
	                |ГДЕ
	                |	НЕ ОбменСМобильнымПриложением.ПометкаУдаления"; 
	
	Выборка = Запрос.Выполнить().Выбрать();
	
	Пока Выборка.Следующий() Цикл
		ОбменДанными.Получатели.Добавить(Выборка.Ссылка);
	КонецЦикла;
	
	
КонецПроцедуры
#КонецЕсли   

 ```

</details>

2. Механизм синхронизации данных на стороне мобильного приложения - созданы константы для хранения адреса подключения к базе, логина и пароля, и обработка с командой для синхронизации данных в результате которой создаются документы, полученные из центральной базы. Создан план обмена, и реализована регистрация документов "Доставка" при записи, также при синхронизации данных - после получения данных из декстопной ИБ выгружаются фотографии из зарегистрированных на узле плана обмена документов. 

   * Форма обработки с константами и командой

    ![image](https://github.com/user-attachments/assets/0900a348-8496-459f-badd-d434579b7b17)

  * Модуль формы обработки

```bsl
    
&НаСервере
Процедура ПриСозданииНаСервере(Отказ, СтандартнаяОбработка)
	// получаем константы Адрес ЦБ. Логин, Пароль
	
	АдресЦентральнойБазы = Константы.АдресЦентральнойБазы.Получить();
	Логин = Константы.ЛогинЦентальнойБазы.Получить();
	Пароль = Константы.ПарольЦетральнойБазы.Получить();
КонецПроцедуры

&НаКлиенте
Процедура АдресЦентральнойБазыПриИзменении(Элемент)
	СохранитьНастройки ();
КонецПроцедуры

&НаКлиенте
Процедура ЛогинПриИзменении(Элемент)
	СохранитьНастройки ();
КонецПроцедуры

&НаКлиенте
Процедура ПарольПриИзменении(Элемент)
	СохранитьНастройки ();
КонецПроцедуры

&НаСервере
Процедура СохранитьНастройки ()
	//устанавливаем конcтанты
	Константы.АдресЦентральнойБазы.Установить(АдресЦентральнойБазы);
	Константы.ЛогинЦентальнойБазы.Установить(Логин);   
	Константы.ПарольЦетральнойБазы.Установить(Пароль);

КонецПроцедуры

Функция УстановитьСоединение (ПараметрыПодключения)

	Возврат Новый HTTPСоединение (ПараметрыПодключения.ИмяСервера,,ПараметрыПодключения.Логин, ПараметрыПодключения.Пароль,,60, ПараметрыПодключения.ЗащищенноеСоединение);
	
КонецФункции

&НаСервере
Процедура ОбменятьсяДаннымиСЦентральнойБазойНаСервере()
	// Разбиваем адрес http://192.168.149.5/BSP
	// /hs/mobile/exchange
	ПараметрыПодключения = ПолучитьПараметры ();
	
	СистемнаяИнформация = Новый СистемнаяИнформация;
	ИдентификаторМобильного = СистемнаяИнформация.ИдентификаторКлиента;
	
	//ищем центральный узел обмена
	Узел = ПланыОбмена.ОбменСМобильнымПриложением.НайтиПоКоду("main");  
	
	//если не нашли создаем новый и регистрируем изменения
	СоздатьЦентральныйУзелИВыполнитьПервичнуюРегистрацию(Узел);

	ТекущийУзел = ПланыОбмена.ОбменСМобильнымПриложением.ЭтотУзел();
	
	//если нет текущего узла, то создать Узел
	СоздатьУзел(ИдентификаторМобильного, ТекущийУзел);
	
	//получить изменения в мобильной версии и отправить их в ЦБ
	ЗарегистрироватьИзмененияИОтправитьВГлавнуюБазу (Узел, ПараметрыПодключения, ИдентификаторМобильного);
	
	//получаем данные из ЦБ
	ПолучитьДанныеИзЦентральнойБазы(ИдентификаторМобильного, ПараметрыПодключения, Узел);

	
КонецПроцедуры

&НаСервере
Процедура ПолучитьДанныеИзЦентральнойБазы(ИдентификаторМобильного, ПараметрыПодключения, Узел)
	
	//установить соединение
	Соединение = УстановитьСоединение (ПараметрыПодключения);
	
	//заголовки
	Заголовки = СоздатьЗаголовки(ИдентификаторМобильного);
	
	// Выполнение HTTP-запроса к центральной базе
	//отправить запрос на получение данных
	ЗапросHTTP = ЗапросКЦентральнойБазе(Заголовки, ПараметрыПодключения);
	
	Ответ = Соединение.Получить(ЗапросHTTP);
	
	//обработать ответ, сравниваем с 200 - ошибка
	
	Если Ответ.КодСостояния <> 200 Тогда
		Сообщить ("Ошибка соединения" + Символы.ПС + "Код состояния " + Ответ.КодСостояния + Символы.ПС + "Описание ошибки: " + Ответ.ПолучитьТелоКакСтроку());
		ВызватьИсключение "Ошибка проверки соединения";
	КонецЕсли;
	
	ТекстОтвета = Ответ.ПолучитьТелоКакСтроку();
	
	// Чтение ответа из центральной базе
	СериализоватьДанныеИзЦентральнойБазы(ТекстОтвета, Узел);


КонецПроцедуры

&НаСервере
Процедура СериализоватьДанныеИзЦентральнойБазы(ТекстОтвета, Узел)
	
	ДоставкиИзЦентральнойБазы = ПрочитатьЗначениеJSON(ТекстОтвета);
	
	КоличествоСозданных = 0;
	КоличествоОбновленных = 0;
	Для каждого Доставка из ДоставкиИзЦентральнойБазы Цикл
		
		//ищем доставку в мобильном приложении по УИ
		ИД = Новый УникальныйИдентификатор (Доставка.Ссылка);
		СсылкаДоставка = Документы.Доставка.ПолучитьСсылку(ИД);
		ОбъектДоставка = СсылкаДоставка.ПолучитьОбъект();
		
		Если ОбъектДоставка = Неопределено Тогда 
			//создаем новый документ
			СоздатьНовыйДокументДоставка(Доставка, ОбъектДоставка, СсылкаДоставка, Узел);
			КоличествоСозданных = КоличествоСозданных + 1;
		Иначе
			
			//обновляем параметры   
			ЗаполнитьРеквизитыИТабличнуюЧастьДокументаДоставка(Доставка, ОбъектДоставка, Узел);
			КоличествоОбновленных = КоличествоОбновленных + 1;	
		КонецЕсли; 
		
	КонецЦикла;
	
	
	ТекстСообщения = СтрШаблон("Обмен выполнен. Создано %1, обновлено %2",
	КоличествоСозданных,
	КоличествоОбновленных);
	
	Сообщить(ТекстСообщения);

КонецПроцедуры


&НаСервере
Процедура СоздатьНовыйДокументДоставка(Доставка, ОбъектДоставка, СсылкаДоставка, Узел)
	
	ОбъектДоставка = Документы.Доставка.СоздатьДокумент();
	ОбъектДоставка.УстановитьСсылкуНового(СсылкаДоставка); 
	
	ЗаполнитьРеквизитыИТабличнуюЧастьДокументаДоставка(Доставка, ОбъектДоставка, Узел);

КонецПроцедуры

&НаСервере
Процедура ЗаполнитьРеквизитыИТабличнуюЧастьДокументаДоставка(Доставка, ОбъектДоставка, Узел)
	
	ОбъектДоставка.Номер = Доставка.Номер;
	ОбъектДоставка.Дата = Дата(Прав(Доставка.Дата, 4) + Сред(Доставка.Дата, 4, 2) + Лев(Доставка.Дата, 2));
	ОбъектДоставка.АдресДоставки = Доставка.АдресДоставки;
	ОбъектДоставка.ПометкаУдаления = Доставка.ПометкаУдаления;
	ОбъектДоставка.Проведен = Доставка.Проведен; 
	ОбъектДоставка.Комментарий = Доставка.Комментарий; 
	
	ДвДанныеФото = Base64Значение(Доставка.Фото);
	ОбъектДоставка.Фото = Новый ХранилищеЗначения(ДвДанныеФото);
	
	//ищем контрагента в мобильном приложении
	СсылкаКонтрагент = ПоискИСозданиеКонтрагента(Доставка);
	
	ОбъектДоставка.Контрагент = СсылкаКонтрагент; 
	
	Если Доставка.Статус = "" Тогда
		ОбъектДоставка.Статус = "";
	Иначе
		ОбъектДоставка.Статус =Перечисления.СтатусыДоставок [Доставка.Статус]; 
	КонецЕсли;
	
	//очищаем ТЧ товары
	ОбъектДоставка.Товары.Очистить();

	//создание табличной части
	Для каждого Товар из Доставка.ТабличнаяЧасть Цикл
		
		НоваяСтрокаТЧ = ОбъектДоставка.Товары.Добавить();  
		
		//поиск номенклатуры в справочнике
		СсылкаНоменклатура = ПоискИСозданиеНоменклатуры(Товар);
		
		НоваяСтрокаТЧ.Номенклатура =  СсылкаНоменклатура;    
		НоваяСтрокаТЧ.Количество =  Товар.Количество; 
	КонецЦикла;
	
	ОбъектДоставка.ОбменДанными.Загрузка = Истина;
	ОбъектДоставка.ОбменДанными.Отправитель = Узел;
	ОбъектДоставка.Записать();
КонецПроцедуры

&НаСервере
Функция ПоискИСозданиеНоменклатуры(Товар)
	
	ИДНоменклатура = Новый УникальныйИдентификатор (Товар.Номенклатура);
	СсылкаНоменклатура = Справочники.Номенклатура.ПолучитьСсылку(ИДНоменклатура);
	ОбъектНоменклатура = СсылкаНоменклатура.ПолучитьОбъект();
	
	Если ОбъектНоменклатура = Неопределено Тогда  
		СоздатьНовуюНоменклатуру(СсылкаНоменклатура, Товар);
	КонецЕсли; 
	
	Возврат СсылкаНоменклатура;

КонецФункции

&НаСервере
Функция ПоискИСозданиеКонтрагента(Доставка)
	
	ИДКонтрагент = Новый УникальныйИдентификатор (Доставка.Контрагент);
	СсылкаКонтрагент = Справочники.Контрагенты.ПолучитьСсылку(ИДКонтрагент);
	ОбъектКонтрагент = СсылкаКонтрагент.ПолучитьОбъект();
	
	Если ОбъектКонтрагент = Неопределено Тогда 
		СоздатьНовогоКонтрагента(Доставка, СсылкаКонтрагент);
	КонецЕсли;
	
	Возврат СсылкаКонтрагент;

КонецФункции

&НаСервере
Процедура СоздатьНовогоКонтрагента(Доставка, СсылкаКонтрагент)
	
	Если Доставка.КонтрагентЭтоГруппа Тогда
		ОбъектКонтрагент = Справочники.Контрагенты.СоздатьГруппу();
	Иначе
		ОбъектКонтрагент = Справочники.Контрагенты.СоздатьЭлемент(); 
	КонецЕсли;
	
	ОбъектКонтрагент.УстановитьСсылкуНового(СсылкаКонтрагент);
	
	ОбъектКонтрагент.Код = Доставка.КонтрагентКод;
	ОбъектКонтрагент.Наименование = Доставка.КонтрагентНаименование;  
	ОбъектКонтрагент.Родитель = Справочники.Контрагенты.ПолучитьСсылку(Новый УникальныйИдентификатор (Доставка.КонтрагентРодитель));  
	
	Для каждого НомерТелефона из Доставка.КонтрагентНомерТелефона Цикл
		ОбъектКонтрагент.НомерТелефона = НомерТелефона.КонтрагентНомерТелефона;
	КонецЦикла; 
	
	ОбъектКонтрагент.Записать();

КонецПроцедуры

&НаСервере
Процедура СоздатьНовуюНоменклатуру(СсылкаНоменклатура, Товар)
	
	Если Товар.НоменклатураЭтоГруппа Тогда
		ОбъектНоменклатура = Справочники.Номенклатура.СоздатьГруппу();
	Иначе
		ОбъектНоменклатура = Справочники.Номенклатура.СоздатьЭлемент(); 
	КонецЕсли;
	
	ОбъектНоменклатура.УстановитьСсылкуНового(СсылкаНоменклатура); 
	ОбъектНоменклатура.Код = Товар.НоменклатураКод;
	ОбъектНоменклатура.Наименование = Товар.НоменклатураНаименование;
	ОбъектНоменклатура.Родитель = Справочники.Номенклатура.ПолучитьСсылку(Новый УникальныйИдентификатор (Товар.НоменклатураРодитель));
	
	ОбъектНоменклатура.Записать();

КонецПроцедуры


&НаСервере
Функция ЗапросКЦентральнойБазе(Заголовки, ПараметрыПодключения)
	
	АдресРесурса = ПараметрыПодключения.ИмяРесурcа + "/hs/mobile/exchangeDelivery";
	Запрос = Новый HTTPЗапрос (АдресРесурса, Заголовки);
	Возврат Запрос;

КонецФункции

&НаСервере
Функция СоздатьЗаголовки(ИдентификаторМобильного)
	
	Заголовки = Новый Соответствие (); 
	Заголовки.Вставить("X_Mobile_ID", Строка(ИдентификаторМобильного));
	Возврат Заголовки;

КонецФункции

&НаСервере
Процедура СоздатьУзел(ИдентификаторМобильного, ТекущийУзел)
	
	Если Не ЗначениеЗаполнено(ТекущийУзел.Код) Тогда
		УзелОбъект = ТекущийУзел.ПолучитьОбъект();
		УзелОбъект.Код = ИдентификаторМобильного;
		УзелОбъект.Наименование = ИдентификаторМобильного;
		УзелОбъект.Записать();
	КонецЕсли;

КонецПроцедуры

&НаСервере
Процедура СоздатьЦентральныйУзелИВыполнитьПервичнуюРегистрацию(Узел)
	
	Если Не ЗначениеЗаполнено(Узел) Тогда
		УзелОбъект = ПланыОбмена.ОбменСМобильнымПриложением.СоздатьУзел();
		УзелОбъект.Код = "main";
		УзелОбъект.Наименование = "Центральный узел";
		УзелОбъект.Записать();		
		Узел = УзелОбъект.Ссылка;
		
		ВыполнитьПервичнуюРегистрацию(Узел);
		
	КонецЕсли;
КонецПроцедуры   

Процедура ВыполнитьПервичнуюРегистрацию(Узел)
	Запрос = Новый Запрос;
	Запрос.Текст = "ВЫБРАТЬ
	               |	Доставка.Ссылка КАК Ссылка
	               |ИЗ
	               |	Документ.Доставка КАК Доставка";
	
	Выборка = Запрос.Выполнить().Выбрать();
	ДанныеКРегистрации = Новый Массив;
	
	//обходим выборку и записываем изменения
	Пока Выборка.Следующий() Цикл
		ДанныеКРегистрации.Добавить(Выборка.Ссылка);
	КонецЦикла;
	Если ДанныеКРегистрации.Количество() > 0 Тогда
		ПланыОбмена.ЗарегистрироватьИзменения(Узел, ДанныеКРегистрации); 
	КонецЕсли;
	
КонецПроцедуры

Функция ПолучитьПараметры ()
	
	ПараметрыПодключения = Новый Структура;
	
	Если Лев(АдресЦентральнойБазы, 5) = "https" Тогда
		ЗащищенноеСоединение = Новый ЗащищенноеСоединениеOpenSSL();
	Иначе 
		ЗащищенноеСоединение = Неопределено;
	КонецЕсли;
	
	НачалоАдресаСервера = СтрНайти(АдресЦентральнойБазы, "://")+3; //8 - делим адрес
	АдресСервера = Сред (АдресЦентральнойБазы, НачалоАдресаСервера); //192.168.149.5/BSP - обрезаем адрес сервера
	НачалоАдресаРесурса = СтрНайти(АдресСервера, "/");  //14
	ИмяСервера = Лев (АдресСервера, НачалоАдресаРесурса-1); //192.168.149.5/ отделить имя сервера от адреса
	ИмяРесурcа = Сред (АдресСервера,НачалоАдресаРесурса+1); // /BSP
	
	ПараметрыПодключения.Вставить("ИмяСервера",ИмяСервера);
	ПараметрыПодключения.Вставить("ИмяРесурcа",ИмяРесурcа);  
	ПараметрыПодключения.Вставить("ЗащищенноеСоединение",ЗащищенноеСоединение);
	ПараметрыПодключения.Вставить("Логин",Логин);  
	ПараметрыПодключения.Вставить("Пароль",Пароль);
	
	
	Возврат ПараметрыПодключения;
	
КонецФункции

Функция ЗарегистрироватьИзмененияИОтправитьВГлавнуюБазу (Узел, ПараметрыПодключения, ИдентификаторМобильного)	
	//формирование струткуры данных для отправки

	//если узел есть, то проверяем данные в узле для изменений
	// Получение зарегистрированных данных
	МассивДоставокДляВыгрузки = ПолучитьИзмененныеДанные(Узел);

	//создаем пакет данных
	ТелоОтвета = ЗаписатьЗначениеJSON(МассивДоставокДляВыгрузки);
	
	// Создание нового HTTP соединения.
	Соединение = УстановитьСоединение (ПараметрыПодключения);
	
	// Формирование заголовков. 
	Заголовки = СоздатьЗаголовки(ИдентификаторМобильного);
	
	// Выполнение HTTP-запроса к центральной базе
	//отправить запрос на получение данных
	ЗапросHTTP = ЗапросКЦентральнойБазе(Заголовки, ПараметрыПодключения);
	
	ЗапросHTTP.УстановитьТелоИзСтроки(ТелоОтвета);
	
	// Отправка данных методом POST.
	Ответ = Соединение.ОтправитьДляОбработки (ЗапросHTTP); 
	
	//обработать ответ, сравниваем с 200 - ошибка
	Если Ответ.КодСостояния <> 200 Тогда
		Сообщить ("Ошибка соединения" + Символы.ПС + "Код состояния " + Ответ.КодСостояния + Символы.ПС + "Описание ошибки: " + Ответ.ПолучитьТелоКакСтроку());
		ВызватьИсключение "Ошибка проверки соединения";
	КонецЕсли;
	
	Возврат ""; 
	
КонецФункции

Функция ПолучитьИзмененныеДанные(Узел)
	
	
	Запрос = Новый Запрос;
	Запрос.Текст = "ВЫБРАТЬ
					|	ДоставкаИзменения.Узел КАК Узел,
					|	ДоставкаИзменения.Ссылка.Комментарий КАК Комментарий,
					|	ДоставкаИзменения.Ссылка.Статус КАК Статус,
					|	ДоставкаИзменения.Ссылка.Фото КАК Фото,
					|	ДоставкаИзменения.Ссылка.Ссылка КАК Ссылка
					|ИЗ
					|	Документ.Доставка.Изменения КАК ДоставкаИзменения
					|ГДЕ
					|	ДоставкаИзменения.Узел = &Узел";
	
	Запрос.УстановитьПараметр("Узел",Узел);
	РезультатЗапроса = Запрос.Выполнить();
	Выборка = РезультатЗапроса.Выбрать();
	
	// Сериализация зарегистрированных данных
	МассивДоставокДляВыгрузки = Новый Массив;
	МассивДляОтменыРегистрации = Новый Массив;
	Пока Выборка.Следующий() Цикл   
		МассивДляОтменыРегистрации.Добавить(Выборка.Ссылка);
		ДоставкиИзменения = Новый Структура; 
		ДоставкиИзменения.Вставить("Ссылка", Строка(Выборка.Ссылка.УникальныйИдентификатор()));
		ДоставкиИзменения.Вставить("Комментарий", Выборка.Комментарий);
		ДоставкиИзменения.Вставить("Статус", XMLСтрока(Выборка.Статус));
		ДоставкиИзменения.Вставить("Фото", Base64Строка(Выборка.Фото.Получить()));
		МассивДоставокДляВыгрузки.Добавить(ДоставкиИзменения);  
	КонецЦикла;
	
	//отменяем регистрацию
	Если МассивДляОтменыРегистрации.Количество() > 0 Тогда
		ПланыОбмена.УдалитьРегистрациюИзменений(Узел, МассивДляОтменыРегистрации);  
	КонецЕсли;
	
	Возврат МассивДоставокДляВыгрузки;

КонецФункции

&НаКлиенте
Процедура ОбменятьсяДаннымиСЦентральнойБазой(Команда)
	ОбменятьсяДаннымиСЦентральнойБазойНаСервере();
КонецПроцедуры
```


