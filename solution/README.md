# Feature selection

## Subject AI6
```matlab
% Cz: 18+++, 20+++, 22++
selected_features = [frequencies(18), channels({'Cz'}); frequencies(20), channels({'Cz'}); frequencies(22), channels({'Cz'})];
```

## Subject AI7
One good feature map, two bad feature maps.
```matlab
% C3: 14
% C4: 14
selected_features = [frequencies(14), channels({'C3'}); frequencies(14), channels({'C4'})];
```

## Subject AI8
```matlab
% Cz: 24+
% C3: 14++
% C4: 14++
selected_features = [frequencies(14), channels({'C3'}); frequencies(14), channels({'C4'}); frequencies(24), channels({'Cz'})];
```

## Subject AJ1
```matlab
% C3: 10+, 12+
% C4: 10+, 12+
selected_features = [frequencies(10), channels({'C3'}); frequencies(12), channels({'C3'}); frequencies(10), channels({'C4'}); frequencies(12), channels({'C4'})];
```

## Subject AJ3
```matlab
% C3: 12+++, 14+++
% C4: 12++, 14++
selected_features = [frequencies(12), channels({'C3'}); frequencies(14), channels({'C3'}); frequencies(12), channels({'C4'}); frequencies(14), channels({'C4'})];
```

## Subject AJ4
```matlab
% C1: 12++, 14++
% C3: 12+++, 14+
selected_features = [frequencies(12), channels({'C1'}); frequencies(14), channels({'C1'}); frequencies(12), channels({'C3'}); frequencies(14), channels({'C3'})];
```

## Subject AJ7
```matlab
% C4: 12++
selected_features = [frequencies(12), channels({'C4'})];
```

## Subject AJ9
```matlab
% C1: 12++
% C2: 12++
selected_features = [frequencies(12), channels({'C1'}); frequencies(12), channels({'C2'})];
```

## Overall from subjects
% Cz: 18+, 20+, 22+, 24+
% C1: 12++, 14+
% C2: 12+
% C3: 10+, 12+++, 14++++
% C4: 10+, 12+++, 14+++

## Population
```matlab
% C3: 12, 14
% C4: 12, 14
selected_features = [frequencies(12), channels({'C3'}); frequencies(14), channels({'C3'}); frequencies(12), channels({'C4'}); frequencies(14), channels({'C4'})];
```