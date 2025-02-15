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


