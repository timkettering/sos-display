'use strict';

angular.module('sos.canvas', [])
.controller('CanvasCtrl', ['$scope', function($scope) {
	
	$scope.stage = null;
	$scope.canvasID = "sos-canvas";
	$scope.canvasDim = {
		width: 192,
		height: 320
	};
	$scope.canvasPos = {
		x: 10,
		y: 10
	};
	
	$scope.devProdToggle = true;
	
	$scope.mediaList = [];
	
	$scope.$watch('devProdToggle', function(newState) {
		
		// prepare for rotation
		$scope.canvasDim = { width: $scope.canvasDim.height, height: $scope.canvasDim.width };
		
		if(newState) {
			// if newState is true, dev mode is enabled
			console.log("DEV MODE");
			$scope.stage.setTransform(0, 0, 1, 1, 0);
		} else {
			console.log("PROD MODE");
			$scope.stage.setTransform(192, 0, 1, 1, 90);
		}
				
	}, true);
	
	$scope.$watch('canvasDim', function(newDim) {
		$scope.setCanvasSize(newDim.width, newDim.height, true);
	}, true);
	
	$scope.$on("error", function(err) {
		console.log("Registered error:", err);
	});
	
	$scope.initCanvas = function() {
		
		console.log("Initializing <CANVAS> with id:", $scope.canvasID);
		
		// create the media list
			// available media 
		$scope.mediaList = [
			{ name: "Draw red circle", fn: $scope.drawRedCircle },
			{ name: "Play movie.", fn: function() {
				
				var vidEl = document.createElement('video');
				vidEl.src = "media/small.mp4";

				vidEl.oncanplaythrough = function() {

					var video = new createjs.Bitmap(vidEl);
					video.scaleX = 2;
					video.scaleY = 2;
					$scope.stage.addChild(video);
					vidEl.play();
				}		
			}},
			{ name: "Slow Clap", fn: function() {

				var gif = new createjs.Bitmap("media/citizen-kane-clapping.gif");
				gif.image.onload = function() {
					gif.scaleX = $scope.canvasDim.width / gif.getBounds().width;
					gif.scaleY = $scope.canvasDim.height / gif.getBounds().height;
					$scope.stage.addChild(gif);
				};
			}},
			{ name: "Spritesheet Slow Clap", fn: function() {
				
				var data = {
				    images: ["media/spritesheet.png"],
				    frames: {width:400, height:300},
				    animations: {
				        def: [0,6,"def"]
				    }
				};
				var spriteSheet = new createjs.SpriteSheet(data);
				var sprite = new createjs.Sprite(spriteSheet);
				
				sprite.gotoAndPlay("def");
				$scope.stage.addChild(sprite);
			}}
		];
		
		 //Create a stage by getting a reference to the canvas
	    $scope.stage = new createjs.Stage($scope.canvasID);
	    $scope.setCanvasSize($scope.canvasDim.width, $scope.canvasDim.height, false);

	    // set up the ticker
	    createjs.Ticker.setFPS(20);
	    createjs.Ticker.addEventListener('tick', function() {
		   $scope.stage.update(); 
	    });
	}
	
	$scope.drawRedCircle = function() {
	    //Create a Shape DisplayObject.
	    var circle = new createjs.Shape();
	    circle.graphics.beginFill("red").drawCircle(0, 0, 40);
	    //Set position of Shape instance.
	    circle.x = circle.y = 50;
	    //Add Shape instance to stage display list.
	    $scope.stage.addChild(circle);		
	}
	
	$scope.playMedia = function(index) {
		
		$scope.clearStage();
		
		var media = $scope.mediaList[index];
		console.log("Playing media:", media.name);
		media['fn']()
	}
	
	$scope.clearStage = function() {
		console.log("Clearing stage...");
		$scope.stage.removeAllChildren();
	}
	
	$scope.setCanvasSize = function(width, height, doUpdate) {
		// browser viewport size
/*
		var w = window.innerWidth;
		var h = window.innerHeight;
		
		// stage dimensions
		var ow = 640; // your stage width
		var oh = 480; // your stage height
		
		if (keepAspectRatio)
		{
		    // keep aspect ratio
		    var scale = Math.min(w / ow, h / oh);
		    stage.scaleX = scale;
		    stage.scaleY = scale;
		
		   // adjust canvas size
		   stage.canvas.width = ow * scale;
		  stage.canvas.height = oh * scale;
		}
		else
		{
		    // scale to exact fit
		    stage.scaleX = w / ow;
		    stage.scaleY = h / oh;
		
		    // adjust canvas size
		    stage.canvas.width = ow * stage.scaleX;
		    stage.canvas.height = oh * stage.scaleY;
		   }
*/

		$scope.stage.canvas.width = width;
		$scope.stage.canvas.height = height;
		
		 // update the stage
		 if(doUpdate) {
			 $scope.stage.update();
		 }
	}
}]);