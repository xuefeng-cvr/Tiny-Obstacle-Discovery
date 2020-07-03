function [integralMap] = compute_integralMap(map)
integralMap = cumsum(cumsum(map, 2), 1);
integralMap(2:end+1,:) = integralMap(:,:);
integralMap(:,2:end+1) = integralMap(:,:);
integralMap(1,:) = 0;
integralMap(:,1) = 0;
end

