import XCTest
import ReactiveSwift
import RxSwift
import ReactiveKit
import Snail
import Interstellar
import enum Result.NoError
@testable import FRPBenchmark

let producerRange = (1..<100_000)
let composeRange = (1..<1_000)
let subscriberRange = (1..<100)

func isEven(_ value: Int) -> Bool {
    return value % 2 == 0
}

extension CountableRange where Bound == Int {
    func times(_ f: () -> Void) {
        forEach { _ in f() }
    }
}

class FRPBenchmarkTests: XCTestCase {
    // MARK: - Producer
    
    func test_measure_Interstellar_1() {
        measure {
            var counter : Int = 0
            let producer = Interstellar.Observable<Int>()
            producer.subscribe { counter += $0 }
            producerRange.forEach(producer.update)
        }
    }
    
    func test_measure_ReactiveKit_1() {
        measure {
            var counter : Int = 0
            let signal = ReactiveKit.Signal<Int, NoError> { o in
                producerRange.forEach(o.next)
                return NonDisposable.instance
            }
            _ = signal.observeNext(with: { counter += $0 })
        }
    }
    
    func test_measure_ReactiveSwift_1() {
        measure {
            var counter : Int = 0
            let producer = SignalProducer<Int, NoError> { o, d in
                producerRange.forEach(o.send)
            }
            producer.startWithValues { counter += $0 }
        }
    }
    
    func test_measure_RxSwift_1() {
        measure {
            var counter : Int = 0
            let observable = RxSwift.Observable<Int>.create { o in
                producerRange.forEach(o.onNext)
                return Disposables.create()
            }
            _ = observable.subscribe(onNext: { counter += $0 })
        }
    }
    
    func test_measure_Snail_1() {
        measure {
            var counter : Int = 0
            let producer = Snail.Observable<Int>()
            producerRange.forEach { producer.on(.next($0)) }
            producer.subscribe(onNext: { counter += $0 })
        }
    }
    
    // MARK: - Multiple Subscriptions
    
    func test_measure_Interstellar_2() {
        measure {
            var counter : Int = 0
            let property = Interstellar.Observable<Int>(0)
            subscriberRange.times {
                property.subscribe { counter += $0 }
            }
            producerRange.forEach(property.update)
        }
    }
    
    func test_measure_ReactiveKit_2() {
        measure {
            var counter : Int = 0
            let property = ReactiveKit.Property.init(0)
            subscriberRange.times {
                _ = property.observeNext { counter += $0 }
            }
            producerRange.forEach { property.value = $0 }
        }
    }
    
    func test_measure_ReactiveSwift_2() {
        measure {
            var counter : Int = 0
            let property = ReactiveSwift.MutableProperty<Int>(0)
            subscriberRange.times {
                property.producer.startWithValues { counter += $0 }
            }
            producerRange.forEach { property.value = $0 }
        }
    }
    
    func test_measure_RxSwift_2() {
        measure {
            var counter : Int = 0
            let variable = RxSwift.Variable(0)
            subscriberRange.times {
                _ = variable.asObservable().subscribe(onNext: { counter += $0 })
            }
            producerRange.forEach { variable.value = $0 }
        }
    }
    
    func test_measure_Snail_2() {
        measure {
            var counter : Int = 0
            let variable = Snail.Variable(0)
            subscriberRange.times {
                _ = variable.asObservable().subscribe(onNext: { counter += $0 })
            }
            producerRange.forEach { variable.value = $0 }
        }
    }
    
    // MARK: - Filter + Map + Subscribe
    
    func test_measure_Interstellar_3() {
        measure {
            let o = Interstellar.Observable<Int>()
            subscriberRange.times {
                _ = o.filter(isEven).map(String.init).subscribe { _ in }
            }
            producerRange.forEach(o.update)
        }
    }
    
    func test_measure_ReactiveKit_3() {
        measure {
            let property = ReactiveKit.Property.init(0)
            subscriberRange.times {
                _ = property.filter(isEven).map(String.init).observeNext { _ in }
            }
            producerRange.forEach { property.value = $0 }
        }
    }
    
    func test_measure_ReactiveSwift_3() {
        measure {
            let (signal, observer) = ReactiveSwift.Signal<Int, NoError>.pipe()
            subscriberRange.times {
                signal.filterMap { isEven($0) ? String($0) : nil }.observeValues { _ in }
            }
            producerRange.forEach(observer.send)
        }
    }
    
    func test_measure_RxSwift_3() {
        measure {
            let variable = RxSwift.PublishSubject<Int>()
            let o = variable.asObservable()
            subscriberRange.times {
                _ = o.filter(isEven).map(String.init).subscribe(onNext: { _ in })
            }
            producerRange.forEach(variable.onNext)
        }
    }
    
    // MARK: - Combine Latest
    
    func test_measure_ReactiveKit_4() {
        measure {
            let v1 = ReactiveKit.Property<Int>(0)
            let v2 = ReactiveKit.Property<Int>(0)
            let o1 = v1.toSignal()
            let o2 = v2.toSignal()
            subscriberRange.times {
                _ = combineLatest(o1, o2)
                    .observeNext { _ in }
            }
            composeRange.forEach {
                v1.value = $0
                v2.value = $0
            }
        }
    }
    
    func test_measure_ReactiveSwift_4() {
        measure {
            let (s1, o1) = ReactiveSwift.Signal<Int, NoError>.pipe()
            let (s2, o2) = ReactiveSwift.Signal<Int, NoError>.pipe()
            subscriberRange.times {
                ReactiveSwift.Signal<Int, NoError>
                    .combineLatest([s1,s2])
                    .observeValues { _ in }
            }
            composeRange.forEach {
                o1.send(value: $0)
                o2.send(value: $0)
            }
        }
    }
    
    func test_measure_RxSwift_4() {
        measure {
            let v1 = RxSwift.PublishSubject<Int>()
            let v2 = RxSwift.PublishSubject<Int>()
            let o1 = v1.asObservable()
            let o2 = v2.asObservable()
            subscriberRange.times {
                _ = Observable.combineLatest([o1, o2])
                    .subscribe(onNext: { _ in })
            }
            composeRange.forEach {
                v1.onNext($0)
                v2.onNext($0)
            }
        }
    }
    
    // MARK: - Merge
    
    func test_measure_Interstellar_5() {
        measure {
            let o1 = Interstellar.Observable<Int>()
            let o2 = Interstellar.Observable<Int>()
            subscriberRange.times {
                _ = Interstellar.Observable<Int>
                    .merge([o1, o2])
                    .subscribe { _ in }
            }
            composeRange.forEach {
                o1.update($0)
                o2.update($0)
            }
        }
    }
    
    func test_measure_ReactiveKit_5() {
        measure {
            let v1 = ReactiveKit.Property<Int>(0)
            let v2 = ReactiveKit.Property<Int>(0)
            let o1 = v1.toSignal()
            let o2 = v2.toSignal()
            subscriberRange.times {
                _ = merge(o1, o2)
                    .observeNext { _ in }
            }
            composeRange.forEach {
                v1.value = $0
                v2.value = $0
            }
        }
    }
    
    func test_measure_ReactiveSwift_5() {
        measure {
            let (s1, o1) = ReactiveSwift.Signal<Int, NoError>.pipe()
            let (s2, o2) = ReactiveSwift.Signal<Int, NoError>.pipe()
            subscriberRange.times {
                ReactiveSwift.Signal<Int, NoError>
                    .merge([s1,s2])
                    .observeValues { _ in }
            }
            composeRange.forEach {
                o1.send(value: $0)
                o2.send(value: $0)
            }
        }
    }
    
    func test_measure_RxSwift_5() {
        measure {
            let v1 = RxSwift.PublishSubject<Int>()
            let v2 = RxSwift.PublishSubject<Int>()
            let o1 = v1.asObservable()
            let o2 = v2.asObservable()
            subscriberRange.times {
                _ = Observable.merge([o1, o2])
                    .subscribe(onNext: { _ in })
            }
            composeRange.forEach {
                v1.onNext($0)
                v2.onNext($0)
            }
        }
    }
}
