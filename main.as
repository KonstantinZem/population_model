﻿// Author: Konstantin Zemoglyadchuk konstantinz@bk.ru
// Copyright (C) 2017 Konstantin Zemoglyadchuk
// This program is free software; you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation; either version 2 of the License, or
// (at your option) any later version.
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

package{
    
    import flash.display.Sprite;
	import flash.events.Event; 
	import flash.events.TimerEvent; 
	import flash.utils.Timer;
	import konstantinz.community.comStage.*;
	import konstantinz.community.comStage.behaviour.BehaviourChoicer;
	import konstantinz.community.auxilarity.*;
	import konstantinz.community.auxilarity.gui.*;
   
    public class main extends Sprite{
		
		private const IND_NUMB:String = 'ind_numb:';//Пометка сообщения о количестве особей
		private const MIN_INDIVIDUAL_CRITICAL_NUMBER:int = 5;//Минимально подходящие для отслеживания статистики количество особей
		private const MAX_INDIVIDUAL_CRITICAL_NUMBER:int = 3000;
		private const PAUSE_AFTER_CYCLE:int = 5;//Время паузы между циклами передвижения особей
		private const DEAD_INDIVIDUALS_REMOVING_INTERVAL:int = 100;
		
		private var stgHeight:int;
		private var stgWidth:int;
		private var indNumber:int;
		private var debugLevel:String;
		private var msgString:String;
		private var statRefreshTime:String;//Время обновления статистической информации
		private var versionText:Sprite;
		private var statusBar:StatusBar;
		private var msgWindow:TextWindow;
		private var messenger:Messenger;
		private var behaviourChoicer:BehaviourChoicer;
		private var eventsForPlugins:Object;
		private var eventsForPluginsList:Array;
		private var modelEvent:ModelEvent;
		private var stepTimer:Timer;
		private var numberOfCycles:int;
		private var individualPictures:Vector.<IndividualGraphicInterface>
		
		public var individuals:Vector.<Individual>;
		public var model:Sprite;
		public var plugins:PluginLoader;
		public var configuration:ConfigurationContainer;
		public var commStage:CommunityStage;
		public var startStopButtonEvent:DispatchEvent;
		public var reloadButtonEvent:DispatchEvent;
		public var startStopButton:KzSimpleButton;
		public var reloadButton:KzSimpleButton;
		public var stageEvent:DispatchEvent;

		public function main(){
			stgHeight = parent.stage.stageHeight;
			stgWidth = parent.stage.stageWidth;
			initConfig();	
			}
        
        public function getNewStatistics(e:Event):void{//При получении информации, которую нужно сохранить для дальнейшего анализа
				Accumulator.instance.pushToBuffer(e.target.msg);//Передаем ее в компонент, формирующий таблицу
				statusBar.setTexSource(Accumulator.instance.statusBarText);//А затем выводим текущую статистическую информацию в статусную строку
				behaviourChoicer.getConditionsMeaning(e.target.msg);
				stageEvent.message = e.target.msg
				stageEvent.target = e.target.messageMark;
				stageEvent.newStatistic();//Рассылаем информацию о новой статистике например плагинам
				
			    }
        
        private function removeAllObjects():void{//Очищает все объекты программы перед ее перезапуском
			var counter:int;
			Accumulator.instance.clear();
			
			startStopButtonEvent.removeEventListener(ModelEvent.FIRST_CLICK, onStartClick);
			startStopButtonEvent.removeEventListener(ModelEvent.SECOND_CLICK, onStopClick);
			reloadButtonEvent.removeEventListener(ModelEvent.CLICKING, onReloadClick);
			
			messenger.removeEventListener(Messenger.HAVE_EXT_DATA, getNewStatistics);
			messenger = null;
			
			counter = individuals.length;

			model.removeChild(commStage);
			if(plugins != null){
				model.removeChild(plugins);
				}
			
			statusBar.clear();
			startStopButton.clear();
			reloadButton.clear();
			model.removeChild(versionText);
			model.removeChild(statusBar);
			
			removeChild(model);
			
			configuration = null;
			commStage = null;
			reloadButton = null;
			startStopButton = null;
			plugins = null;
			}
        
        private function initConfig():void{
			configuration = ConfigurationContainer.instance;
			configuration.setConfigFileName('configuration.xml');
			configuration.addEventListener(ConfigurationContainer.LOADED, init);//
			configuration.addEventListener(ConfigurationContainer.LOADING_ERROR, init);//Если не найдем конфигурационного файла, все равно загружаем программу дальше
			
			model = new Sprite();
			addChild(model);
			}
        
		private function init(e:Event):void{
			var initPosition:String;//Каким образом будут добавлятся первые особи
			var intX:int = 0;//Первоначальная координата по x
			var intY:int = 0;//Первоначальная координата по y
			numberOfCycles = 0;
			
			configuration.removeEventListener(ConfigurationContainer.LOADED, init);//Эти листенеры уже отработали и не неужны
			configuration.removeEventListener(ConfigurationContainer.LOADING_ERROR, init);
			
			debugLevel = configuration.getOption('main.debugLevel'); //Нужно ли отображать отладочную информацию
			messenger = new Messenger(debugLevel);
			messenger.setMessageMark('Main');
			messenger.addEventListener(Messenger.HAVE_EXT_DATA, getNewStatistics);
						
			versionText = new myVersion('0.95',debugLevel);
			modelEvent = new ModelEvent();//Будем брать основные константы от сюда
			
			stepTimer = new Timer(PAUSE_AFTER_CYCLE);
			stepTimer.addEventListener(TimerEvent.TIMER, makeToStepNextIndividual);
			
			if(configuration.getOption('main.behaviourSwitching.enable') == 'true'){
			
				behaviourChoicer = new BehaviourChoicer(configuration, debugLevel);
				behaviourChoicer.addEventListener(BehaviourChoicer.BEHAVIOUR_HAS_FOUND, onConditionsChange)
				}
			
			initPosition = configuration.getOption('main.initPosition');
			model.addChild(versionText);
			
			versionText.x = 10;
			versionText.y = 0;

			commStage = new CommunityStage(stgHeight+10,stgWidth+20,configuration);
			model.addChild(commStage);
			commStage.x = 10;
			commStage.y = 20;
			commStage.scaleX = 0.9;
			commStage.scaleY = 0.9;
			
			indNumber = int(configuration.getOption('main.indQuntaty'));
			
			individuals = new Vector.<Individual>(indNumber);
			individualPictures = new Vector.<IndividualGraphicInterface>(indNumber);
			
			statRefreshTime = configuration.getOption('main.statRefreshTime');
			Accumulator.instance.setDebugLevel(debugLevel);
			Accumulator.instance.setRefreshTime(int(statRefreshTime));//Устанавливаем время обновления статистики
			
			stageEvent = new DispatchEvent();
			
			initGUIElements();
						
			switch(initPosition){//Помещаем первых особей по разным схемам, согласно конфигу
				case 'left-top':
					intX = 0;
					intY = 0;
					addInitIndividuals(intX,intY);
				break;
				
				case 'left-bottom':
					intX = commStage.chessDesk.length-1;
					intY = 0;
					addInitIndividuals(intX,intY);
				break;
				
				case 'right-top':
					intX = 0;
					intY = commStage.chessDesk[1].length-1;
					addInitIndividuals(intX,intY);
				break;
				
				case 'right-bottom':
					intX = commStage.chessDesk.length-1;
					intY = commStage.chessDesk[0].length-1;
					addInitIndividuals(intX,intY);
				break;
				
				case 'center':
					intX = commStage.chessDesk.length/2;
					intY = commStage.chessDesk[0].length/2;
					addInitIndividuals(intX,intY);
				break;
				
				case 'random':
					rndAddInitIndividuals();
				break;
				
				default:
					addInitIndividuals(0,0);
				}
			
			if(configuration.getOption('main.pluginEnable')=='true'){
				try{
				if(configuration.getOption('main.pluginsList') =='Error'){//Если в конфигурационном файле нет списка плагинов
					throw new ArgumentError('Plugins are enabled but plugins list not set');//Прекращаем загрузку
				}
					eventsForPluginsList = new Array();
	
					eventsForPluginsList = [{//Перечисляем при помощи массива каким структурам плагина на какие события надо реагирывать
						sendToRootObject:'getNewStatistics',//Какая структура в главной программе должна реагирывать на событие плагина
						sendFromPluginObject:'messenger',//Какая структура плагина должна посылать событие
						pluginEventHandler:Messenger.HAVE_EXT_DATA
						},
						{
						sendFromRootObject:'startStopButtonEvent',
						sendToPluginObject:'suspendPlugin',
						rootEventHandler:ModelEvent.SECOND_CLICK
						},
						{
						sendFromRootObject:'stageEvent',//При нажатии на кнопку старт плагины стартуют
						sendToPluginObject:'startPlugin',
						rootEventHandler:ModelEvent.FIRST_CLICK
						},
						{
						sendFromRootObject:'stageEvent',
						sendToPluginObject:'suspendPlugin',
						rootEventHandler:ModelEvent.SECOND_CLICK
						},
						{
						sendFromRootObject:'startStopButtonEvent',//При нажатии на кнопку старт плагины стартуют
						sendToPluginObject:'startPlugin',
						rootEventHandler:ModelEvent.FIRST_CLICK
						},
						{
						sendFromRootObject:'reloadButtonEvent',//При нажатии на кнопку перезапуска плагины останавливаются
						sendToPluginObject:'suspendPlugin',
						rootEventHandler:ModelEvent.CLICKING
						},
						{
						sendFromRootObject:'stageEvent',
						sendToPluginObject:'onNewStatistic',//Плагины будут получать информацию от главной программы, которые могут служить сигналом для его включения или выключения
						rootEventHandler:ModelEvent.NEW_STATISTIC
							}];
				
					plugins = new PluginLoader(configuration);//Загружаем плагины
					model.addChild(plugins);
					plugins.setPluginsEventsList(eventsForPluginsList);
					plugins.loaderEvent.addEventListener(ModelEvent.PLUGIN_LOADED, onPluginsLoading);//После загрузки плагинов даем команду на загрузку элементов интерфейса
					plugins.startLoading();//Начинаем загружать плагины, только когда загрузчик плагинов полностью инициирован
					
					msgString = 'Plugins are enabled';
				}catch(e:ArgumentError){
					msgString = e.message;
					messenger.message(msgString, modelEvent.ERROR_MARK);
					addChild(startStopButton);//Просто добавляем кнопку пуск
					addChild(reloadButton);
					}
				
			}else{
				msgString = 'Plugins are disabled';
				addChild(startStopButton);
				addChild(reloadButton);
				}
					
			messenger.message(msgString, modelEvent.INFO_MARK);
				
			}
			
		private function initGUIElements():void{
			try{
				startStopButton = new KzSimpleButton();
				startStopButton.setButtonSkins('pictures/interface/start.png','pictures/interface/stop.png');
				startStopButton.x = 10;
				startStopButton.y = commStage.height + 30;
				startStopButton.height = 30;
				startStopButton.width = 30;
				startStopButtonEvent = startStopButton.buttonEvent;
			
				startStopButtonEvent.addEventListener(ModelEvent.FIRST_CLICK, onStartClick);
				startStopButtonEvent.addEventListener(ModelEvent.SECOND_CLICK, onStopClick);
			
				reloadButton = new KzSimpleButton();//Кнопка перезагрузки модели
				reloadButton.setButtonSkins('pictures/interface/reload.png');
				reloadButton.x = 20 + startStopButton.height;
				reloadButton.y = commStage.height + 30;
				reloadButton.height = 30;
				reloadButton.width = 30;
			
				reloadButtonEvent = reloadButton.buttonEvent;
				reloadButtonEvent.addEventListener(ModelEvent.CLICKING, onReloadClick);
			
				statusBar = new StatusBar();
				model.addChild(statusBar);
				statusBar.setBarAt((70 + startStopButton.width + reloadButton.width), startStopButton.y);
				}catch(e:Error){
					
					}
			}
		
		private function addInitIndividuals(indX:int, indY:int):void{//Добавляем первых особей
			
			for (var i:int = 0; i< indNumber; i++){
				individuals[i] = new Individual(commStage.chessDesk,configuration,i,indX,indY);
				individualPictures[i] = new IndividualGraphicInterface(
					2,
					int(configuration.getOption('main.individualSize')),//Максимальный размер особи
					int(configuration.getOption('main.adultAge'))
					);
				individualPictures[i].drawIndividual();
				commStage.addChild(individualPictures[i].individualBody);
	
				individuals[i].IndividualEvent.addEventListener(ModelEvent.MATURING, addNewIndividuals);
				individuals[i].externalTimer();
				
				
			}
			msgString = IND_NUMB + individuals.length;
			messenger.message(msgString, modelEvent.STATISTIC_MARK);//Сохраняем количество особей для статистики
			
			}
			
		private function rndAddInitIndividuals():void{//Добавляем первых особей в случайных позициях
			
			var indXRnd : int;
			var indYRnd : int;
			
			var chessDeskLengthX:int = commStage.chessDesk.length - 1;
			var chessDeskLengthY:int = commStage.chessDesk[1].length - 1;
			
			for (var i:int = 0; i< indNumber; i++){
				indXRnd = Math.round(Math.random() * chessDeskLengthX);
				indYRnd = Math.round(Math.random() * chessDeskLengthY);
				
				individuals[i] = new Individual(commStage.chessDesk,configuration,i,indXRnd,indYRnd);
				individualPictures[i] = new IndividualGraphicInterface(
					2,
					int(configuration.getOption('main.individualSize')),//Максимальный размер особи
					int(configuration.getOption('main.adultAge'))
					);
				individualPictures[i].drawIndividual();
				commStage.addChild(individualPictures[i].individualBody);
		
				individuals[i].IndividualEvent.addEventListener(ModelEvent.MATURING, addNewIndividuals);
				individuals[i].externalTimer();
			}
			msgString = IND_NUMB + individuals.length;
			messenger.message(msgString, modelEvent.STATISTIC_MARK);//Сохраняем количество особей для статистики
			}
		
		private function addNewIndividuals(e:Event):void {

			var startPos:int = this.individuals.length;
			var stopPos:int = startPos + int(configuration.getOption('main.offspringsQuant'));
				
				for(var i:int = startPos;i<stopPos;i++){
					var newX:int = e.target.currentChessDeskI;
					var newY:int = e.target.currentChessDeskJ;
					individuals[i] = new Individual(commStage.chessDesk, configuration, i,newX,newY);
					individualPictures[i] = new IndividualGraphicInterface(
					2,
					int(configuration.getOption('main.individualSize')),//Максимальный размер особи
					int(configuration.getOption('main.adultAge'))
					);
					
					individualPictures[i].drawIndividual();
					commStage.addChild(individualPictures[i].individualBody);
				
					individuals[i].IndividualEvent.addEventListener(ModelEvent.MATURING, addNewIndividuals);
					individuals[i].externalTimer();
				}
				msgString = IND_NUMB + individuals.length;
			    messenger.message(msgString, modelEvent.STATISTIC_MARK);//Сохраняем количество особей для статистики
			}
		
		private function removeIndividuals():void{
			var counter:int;
			var removedInd:int = 0
			try{
				for(var i:int = 0; i< individuals.length; i++){
					if(individuals[i].statement() == 'dead'){
						
						individuals[i] = null;//Убираем из массива особей
						commStage.removeChild(individualPictures[i].individualBody);
						individualPictures[i] = null
						removedInd++;
						}
					}
				
				counter = individuals.length;	
				for(i= 0; i< individuals.length; i++){
					if(!individuals[i]){
						individuals.splice(i,1);
						individualPictures.splice(i,1);
						i = 0;
					}	
				}
				
				if(!individuals[0]){
						individuals.splice(0,1);
						individualPictures.splice(0,1);
						i = 0;
					}
			
				counter = individuals.length;
				for(i = 0; i< counter; i++){
					individuals[i].name(i);//После ужимания массива делаем так, чтобы имя особи совпадало с ее позицией
				}
			
				msgString = 'Now number of individuals is ' + individuals.length;
				messenger.message(msgString, modelEvent.INFO_MARK);
				msgString = IND_NUMB + individuals.length;
				messenger.message(msgString, modelEvent.STATISTIC_MARK);//Сохраняем количество особей для статистики
			}catch(e:Error){
				messenger.message(e.message, modelEvent.ERROR_MARK);
				}
				catch(e:RangeError){
					messenger.message(e.message, modelEvent.ERROR_MARK);
					}
			}
		
		private function onPluginsLoading(e:ModelEvent):void{
			if(plugins.loaderEvent.pluginName =='last'){
				addChild(startStopButton);//Когда плагины загрузились, показываем кнопку старта. Иначе могут случатся ошибки, когда плагин еще не загрузился а юзер уже пытается его остановить кнопкой
				addChild(reloadButton);
				plugins.loaderEvent.removeEventListener(ModelEvent.PLUGIN_LOADED, onPluginsLoading);//Когда плагины загрузились, больше не нужно ждать сообщений об окончании загрузки
			}
		}
			
		private function onStartClick(e:ModelEvent):void{//Действия по нажатию на кнопку старт
			var counter:int;
			
			if(msgWindow){//Если окно статистики уже было открыто
				removeChild(msgWindow);//Закрываем его
				msgWindow = null;
				}
			
			counter = individuals.length;
			for(var i:int = 0; i< counter; i++){
				individuals[i].statement('moving');
				}
			
			msgString = 'Individuals begin to move';
			messenger.message(msgString, modelEvent.INFO_MARK);
			Accumulator.instance.startRefresh();
			stepTimer.start();
			}
		
		private function onStopClick(e:ModelEvent):void{//Действия по нажатию на кнопку стоп
			var counter:int;
			stepTimer.stop();
			counter = individuals.length;
			for(var i:int = 0; i< counter; i++){
				individuals[i].statement('suspend');
				}
			msgString = 'Individuals has stoped';
			messenger.message(msgString, modelEvent.INFO_MARK);
			
			showMessageWindow();//Показываем статистику в окне
			Accumulator.instance.stopRefresh();//Останавливаем сбор статистики
			}
		
		private function onReloadClick(e:ModelEvent):void{//При нажатии на кнопку перезагрузки модели
			removeAllObjects();//Очищаем все объекты модели
			initConfig();//Запускаем программу с самого начала
			stepTimer.stop();
			}
			
		private function onConditionsChange(e:Event):void{
			var condition:String = e.target.behaviourName;
			var counter:int;
			
			counter = individuals.length;
			for(var i :int = 0; i< individuals.length; i++){
				if(individuals[i] != null){
				individuals[i].behaviour(condition);
				}
			  }
			}
		
		private function showMessageWindow():void{
			
			msgWindow = new TextWindow(400,600, Accumulator.instance.getStatistic());
			addChild(msgWindow);
			msgWindow.x = 100;
			msgWindow.y = 100;
			}
		
		private function makeToStepNextIndividual(e:Event):void{
			indNumber = individuals.length;
			numberOfCycles++;
			
			if(indNumber < MAX_INDIVIDUAL_CRITICAL_NUMBER && indNumber > MIN_INDIVIDUAL_CRITICAL_NUMBER){
			for(var i:int = 0; i< indNumber; i++){
				individuals[i].doStep();
				individualPictures[i].dotStep(//Передаем координаты, куда особи надо переместится на следующем шаге
					individuals[i].placement().x,
					individuals[i].placement().y,
					individuals[i].statement(),
					individuals[i].age()//Взрослая ли уже особь или еще надо расти
					);
				}
			}else{
				stepTimer.stop();
				showMessageWindow();
				Accumulator.instance.stopRefresh();
				msgString = 'Emulation has finished. Number of individuals is ' + individuals.length;
				messenger.message(msgString, modelEvent.INFO_MARK);
				}
			
			if(numberOfCycles > DEAD_INDIVIDUALS_REMOVING_INTERVAL){
				removeIndividuals();
				numberOfCycles = 0;
				}
		if(plugins != null){	
			for(i = 0; i < plugins.plugins.length; i++ ){
				plugins.plugins[i].content.plEntry.process();
				}
			}
		}
    }
}
