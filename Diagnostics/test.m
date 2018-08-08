t1 = [0, 1, 2, 3, 4, 5];
v1 = [-2, -1, 1, 2, 4, 5];

t2 = [0, 0.5, 2.5, 4.2, 5];
v2 = [2.2, 7.4, 3.3, -1, -0.7];

s1.times = t1;
s1.values = v1;

s2.times = t2;
s2.values = v2;

interval.begin = 0.8;
interval.end = 4.6;

implicant = BreachImplicant;
implicant = implicant.addInterval(interval.begin, interval.end);

target = 2;

BreachDiagnostics.diag_or_t(s1, s2, implicant, target);

%signal.times = t;
%signal.values = v;

%interval.begin = 2.5;
%interval.end = 4;

%target_value = 2;


%t2 = [1.5, 2.5];


%implicant = BreachImplicant;
%implicant = implicant.addInterval(3,2);
%implicant = implicant.addInterval(3,5);
%implicant = implicant.addInterval(-inf,-3);
%implicant = implicant.setWorstTime(3.4);
%implicant.getInterval(1)
