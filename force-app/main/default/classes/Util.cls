public with sharing class Util {
    public static Map<Id, Set<Id>> addValueToMapOfSets(Map<Id, Set<Id>> targetMap, Id key, Id value) {
            if (!targetMap.containsKey(key)) {
                targetMap.put(key, new Set<Id>());
            }
            targetMap.get(key).add(value);

        return targetMap;
    }
}