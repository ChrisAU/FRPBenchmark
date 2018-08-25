# FRPBenchmark
Benchmark between multiple FRP libraries

## Results

Each observer was given 100,000 value updates except in the case of `CombineLatest` and `Merge`, they were each given 1,000.

There were 100 subscribers in the `Many` cases below.

|                              | Interstellar | ReactiveKit | ReactiveSwift | RxSwift  | Snail   |
|------------------------------|-------------:|-------------|---------------|----------|---------|
| Single Subscription          | 1.879s       | 1.208s      | 1.846s        | 5.086s   | 1.323s  |
| Many Subscriptions           | 42.074s      | 108.047s    | 165.370s      | 204.180s | 51.966s |
| Many Filter+Map+Subscribe    | 190.941s     | 179.503s    | 129.491s*      | 316.767s | N/A     |
| Many CombineLatest+Subscribe | N/A          | 5.589s      | 7.221s        | 12.879s  | N/A     |
| Many Merge+Subscribe         | 11.273s      | 4.537s      | 6.011s        | 8.510s   | N/A     |

> * ReactiveSwift was given an advantage in this test because it has a `filterMap` operator rather than chaining `filter` then `map`. However, one could extend the existing library to include a `filterMap` and we could conclude we would see better benchmarks.

Interstellar and Snail are very lean which means in complex scenarios they will not be useful without heavy extension.

As you can see ReactiveKit performs the best overall (if we ignore the caveat for ReactiveSwift above).

ReactiveSwift comes with a lot of interesting operators that are missing from the other libraries which make it a more desirable option with only a small impact on performance (over ReactiveKit).

RxSwift is clearly the slowest of the bunch.
