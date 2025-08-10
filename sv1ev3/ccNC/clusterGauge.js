angular.module('gaugesScreen', [])
  .controller('GaugesScreenController', function ($scope, $window) {
    "use strict";

    $scope.gear = 'P';
    $scope.speedData = 0;
    $scope.odoMeter = 0;
    $scope.electricfuel = 0;
    $scope.electricPowerDisplay = 0; // 전력 표시 값

    $scope.previousRange = null;
    $scope.totalBatteryCapacity = 58; // kWh (총 배터리 용량)
    $scope.averageEfficiency = 5.1; // 초기값: 복합 전비 (km/kWh)
    $scope.alpha = 0.1; // 부드럽게 변화시키기 위한 가중치
    
    $scope.calculateRange = function (data) {
        const fuel = parseFloat(data.electrics.fuel || 0); // 현재 배터리 잔량 (0~1)
        const trip = parseFloat(data.electrics.trip || 0); // 현재 주행 거리 (km)
    
        // 초기값 설정
        if ($scope.previousRange === null) {
            $scope.previousRange = fuel * $scope.totalBatteryCapacity * $scope.averageEfficiency;
            $scope.lastFuel = fuel;
            $scope.lastTrip = trip;
            return $scope.previousRange;
        }
    
        const fuelUsed = $scope.lastFuel - fuel; // 연료 사용량
        const tripDistance = trip - $scope.lastTrip; // 주행 거리 변화
    
        // 회생제동 감지 (연료가 증가하면)
        const isRegenerating = fuelUsed < 0;
    
        // 변화가 없으면 이전 값 유지
        if (fuelUsed === 0 && tripDistance === 0) {
            return $scope.previousRange;
        }
    
        // 전비 계산 (회생제동이 아닐 때만)
        if (!isRegenerating && fuelUsed > 0 && tripDistance > 0) {
            const efficiency = tripDistance / (fuelUsed * $scope.totalBatteryCapacity); // 전비 계산
            $scope.averageEfficiency = Math.max(1, Math.min(
                $scope.averageEfficiency + (efficiency - $scope.averageEfficiency) * $scope.alpha, 7
            )); // 전비를 1~7 km/kWh로 제한
        }
    
        if (isRegenerating) {
            // 회생제동으로 추가된 주행 가능 거리 계산
            const regeneratedRange = Math.abs(fuelUsed) * $scope.totalBatteryCapacity * $scope.averageEfficiency;
            const maxRegenRange = 5; // 회생제동 최대 추가 거리 (5km 제한)
            $scope.previousRange += Math.min(regeneratedRange, maxRegenRange); // 제한 적용
        } else {
            // 일반 상태에서 주행 가능 거리 계산
            const remainingBattery = fuel * $scope.totalBatteryCapacity;
            const currentRange = remainingBattery * $scope.averageEfficiency;
            $scope.previousRange = $scope.previousRange + (currentRange - $scope.previousRange) * $scope.alpha; // 부드러운 변화
        }
    
        // 이전 상태 업데이트
        $scope.lastFuel = fuel;
        $scope.lastTrip = trip;
    
        return Math.max($scope.previousRange, 0); // 0 이하 방지
    };
    

    // 데이터 업데이트 함수 정의
    $window.updateData = function (data) {
        $scope.$evalAsync(function() {
            if (data && data.electrics) {

                if (data.electrics.wheelspeed !== undefined) {
                  // 속도 업데이트 (m/s -> km/h 변환)
                  $scope.speedData = (data.electrics.wheelspeed * 3.6).toFixed(0); // km/h
        
                  // Vue.js로 속도 데이터 전달
                  if (typeof $window.updateSpeedData === 'function') {
                    $window.updateSpeedData($scope.speedData);
                  }
                }
        
                if (data.electrics.gear !== undefined) {
                    $scope.gear = data.electrics.gear;
        
                    if (typeof $window.updateGearData === 'function') {
                        $window.updateGearData($scope.gear);
                    }
                }
        
                if (data.electrics.fuel !== undefined) {
                    $scope.electricfuel = Math.round(data.electrics.fuel * 100).toFixed(0);
        
                    if (typeof $window.updateBatteryPercentage === 'function') {
                        $window.updateBatteryPercentage($scope.electricfuel); // Vue.js로 fuel 값 전달
                    }
                }
        
                if (data.electrics.odometer !== undefined) {
                    $scope.odoMeter = (data.electrics.odometer * 0.001).toFixed(0);
        
                    if (typeof $window.updateOdoMeter === 'function') {
                        $window.updateOdoMeter($scope.odoMeter);
                    }
                }
        
                // 주행 가능 거리 계산 및 전달
                const calculatedRange = $scope.calculateRange(data);
                if (typeof $window.updateRemainingRange === 'function') {
                    $window.updateRemainingRange(calculatedRange.toFixed(0)); // 소수점 제거
                }
        
                // 기타 전력 데이터 업데이트
                if (data.customModules && data.customModules.electricMotorData) {
                    const electricPowerDisplay = data.customModules.electricMotorData.electricPowerDisplay || 0;
                    if ($scope.electricPowerDisplay !== electricPowerDisplay) {
                        $scope.electricPowerDisplay = electricPowerDisplay;
                        if (typeof $window.updateElectricPowerDisplay === 'function') {
                            $window.updateElectricPowerDisplay(electricPowerDisplay);
                        }
                    }
                }
        
                // AngularJS 스코프 갱신

                if(!$scope.$$phase) {
                    //$digest or $apply
                    $scope.$apply();
                }
            }
        });
    };
});
