(function(){
    'use strict';

    angular
        .module('bbfone', ['ngMaterial' ] )
        .config(function($mdThemingProvider) {
            $mdThemingProvider.theme('default')
                .primaryPalette('blue-grey')
                .accentPalette('orange')
                .backgroundPalette('blue-grey')
                .dark();
        })
        .controller('StatusCtrl', ['$scope', '$http', '$interval', StatusCtrl]);

    function StatusCtrl($scope, $http, $interval) {
        $scope.type = '';
        $scope.ip = '';
        $scope.hostname = '';
        $scope.connected = false;
        $scope.streaming = false;
        $scope.volume = null;

        // data initial load
        loadData();

        // get data from server every 2 seconds
        $interval(loadData, 2000);

        // reboot call to server
        $scope.reboot = function() {
            $http.get('/reboot');
        }

        // shutdown call to server
        $scope.shutdown = function() {
            $http.get('/shutdown');
        }
        
        // update volume call to server
        $scope.updateVolume = function(value) {
            $http.get('/volume/' + value);
        }

        function loadData() {
            $http.get('/status')
                .then(function(response) {
                    for (var i in response.data) {
                        $scope[i] = response.data[i];
                    }
                });
        }
    }

})();
