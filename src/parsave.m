function  parsave(savepath,v1,n1,v2,n2,v3,n3,v4,n4,v5,n5,v6,n6,v7,n7,v8,n8,v9,n9,v10,n10)

eval([n1,'=v1;']);
switch nargin
    case 21
        name = {n1,n2,n3,n4,n5,n6,n7,n8,n9,n10};
    case 19
        name = {n1,n2,n3,n4,n5,n6,n7,n8,n9};
    case 17
        name = {n1,n2,n3,n4,n5,n6,n7,n8};
    case 15
        name = {n1,n2,n3,n4,n5,n6,n7};
    case 13
        name = {n1,n2,n3,n4,n5,n6};
    case 11
        name = {n1,n2,n3,n4,n5};
    case 9
        name = {n1,n2,n3,n4};
    case 7
        name = {n1,n2,n3};
    case 5
        name = {n1,n2};
    case 3
        name = {n1};
    otherwise
        error('bad number of arguments');
end

for i = 1:length(name)
    eval([name{i},'=v',num2str(i),';']);
end

switch nargin
    case 21
        save(savepath,n1,n2,n3,n4,n5,n6,n7,n8,n9,n10);
    case 19
        save(savepath,n1,n2,n3,n4,n5,n6,n7,n8,n9);
    case 17
        save(savepath,n1,n2,n3,n4,n5,n6,n7,n8);
    case 15
        save(savepath,n1,n2,n3,n4,n5,n6,n7);
    case 13
        save(savepath,n1,n2,n3,n4,n5,n6);
    case 11
        save(savepath,n1,n2,n3,n4,n5);
    case 9
        save(savepath,n1,n2,n3,n4);
    case 7
        save(savepath,n1,n2,n3);
    case 5
        save(savepath,n1,n2);
    case 3
        save(savepath,n1);
end
end

