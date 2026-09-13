package in.ac.iitd.db362.index.hashindex;


// @prism

import in.ac.iitd.db362.index.Index;
import in.ac.iitd.db362.parser.QueryNode;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

import java.util.ArrayList;
import java.util.List;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
// @prism
import java.util.HashSet;
import java.util.Set;

/**
 * Starter code for Extendible Hashing
 * @param <T> The type of the key.
 */
public class ExtendibleHashing<T> implements Index<T> {

    protected static final Logger logger = LogManager.getLogger();

    private final Class<T> type;

    private String attribute; // attribute that we are indexing

   // Note: Do not rename the variable! You can initialize it to a different value for testing your code.
    public static int INITIAL_GLOBAL_DEPTH = 10;


    // Note: Do not rename the variable! You can initialize it to a different value for testing your code.
    public static int BUCKET_SIZE = 4;

    private int globalDepth;

    DateTimeFormatter dateFormatter = DateTimeFormatter.ISO_LOCAL_DATE;

    // directory is the bucket address table backed by an array of bucket pointers
    // the array offset (can be computed using the provided hashing scheme) allows accessing the bucket
    private Bucket<T>[] directory;


    /** Constructor */
    @SuppressWarnings("unchecked")
    public ExtendibleHashing(Class<T> type, String attribute) {
        this.type = type;
        this.globalDepth = INITIAL_GLOBAL_DEPTH;
        int directorySize = 1 << globalDepth;
        this.directory = new Bucket[directorySize];
        for (int i = 0; i < directorySize; i++) {
            directory[i] = new Bucket<>(globalDepth);
        }
        this.attribute = attribute;
    }

    private int getDirectoryIndex(T key, int depth) {

        if (key instanceof Integer) {
            return HashingScheme.getDirectoryIndex((Integer) key, depth);
        } else if (key instanceof Double) {
            return HashingScheme.getDirectoryIndex((Double) key, depth);
        } else if (key instanceof String) {
            return HashingScheme.getDirectoryIndex((String) key, depth);
        } else if (key instanceof LocalDate) {
            return HashingScheme.getDirectoryIndex((LocalDate) key, depth);
        }
        throw new IllegalArgumentException("Unsupported key type: " + key.getClass());
    }

    @SuppressWarnings("unchecked")
    private T convertValue(String value,T val) {

        if ( val instanceof Integer){

            return (T) Integer.valueOf(value);
        }
        else if(val instanceof Double){
            return (T) Double.valueOf(value);
        }
        else if(val instanceof String){
            return (T) value;
        }
        else if(val instanceof LocalDate){
            return (T) LocalDate.parse(value);
        }
        else{
            throw new IllegalArgumentException("Unsupported key type: " + val.getClass());}
    }
    private double convert_to_double(T key) {
        return ((Number)key).doubleValue();
    }

    private int compare(T key1, T key2) {
        if(key1==null || key2==null){
            throw new IllegalArgumentException("cannot compare Null keys");
        }
        // System.out.println("compare called key1 = " + key1 + " key2 = " + key2);

        if(type == Integer.class || type == Double.class) {
            double d1 = convert_to_double(key1);
            double d2 = convert_to_double(key2);
            return Double.compare(d1, d2);
        }
        else if(type == String.class) {
            return ((String)key1).compareTo((String)key2);
        }
        else if(type == LocalDate.class) {
            return ((LocalDate)key1).compareTo((LocalDate)key2);
        }
        else {
            throw new IllegalArgumentException("Unsupported key type");
        }
    }

    // @prism helper functions for evaluating predicates
    private List<Integer> evaluateEquals(QueryNode node) {
        List<Integer> results = new ArrayList<>();

        Set<Bucket<T>> visited = new HashSet<>();
        for(Bucket<T> it : directory){
            if (it!=null){
                visited.add(it);
            }
        }

        for ( Bucket<T> cur_bucket : visited){
            while(cur_bucket!=null){
                for (int j = 0 ; j < cur_bucket.size; j++){
                    if(cur_bucket.keys[j]==null)continue;

                    if(cur_bucket.keys[j].equals(convertValue(node.value,cur_bucket.keys[j]))){
                        results.add(cur_bucket.values[j]);
                    }

                }
                cur_bucket = cur_bucket.next;
            }
        }
        return results;
    }

    private List<Integer> evaluateLessThan(QueryNode node) {
        List<Integer> results = new ArrayList<>();

        Set<Bucket<T>> visited = new HashSet<>();
        for(Bucket<T> it : directory){
            if (it!=null){
                visited.add(it);
            }
        }

        for (Bucket<T> cur_bucket : visited){
            while(cur_bucket!=null){
                for (int j = 0 ; j < cur_bucket.size; j++){
                    if(cur_bucket.keys[j]==null)continue;
                    T key = convertValue(node.value,cur_bucket.keys[j]);
                    if(compare(key,cur_bucket.keys[j])>0){
                        results.add(cur_bucket.values[j]);
                    }
                }
                cur_bucket = cur_bucket.next;
            }
        }
        return results;
    }

    private List<Integer> evaluateGreaterThan(QueryNode node){
        List<Integer> results = new ArrayList<>();

        Set<Bucket<T>> visited = new HashSet<>();   
        for(Bucket<T> it : directory){
            if (it!=null){
                visited.add(it);
            }
        }

        for (Bucket<T> cur_bucket : visited){

            while(cur_bucket!=null){
                for (int j = 0 ; j < cur_bucket.size; j++){
                    if(cur_bucket.keys[j]==null)continue;
                    T key = convertValue(node.value,cur_bucket.keys[j]);
                    if(compare(key,cur_bucket.keys[j])<0){
                        results.add(cur_bucket.values[j]);
                    }

                }
                cur_bucket = cur_bucket.next;
            }
        }
        return results;
    }

    private List<Integer> evaluateRange(QueryNode node){
        List<Integer> results = new ArrayList<>();

        Set<Bucket<T>> visited = new HashSet<>();
        for(Bucket<T> it : directory){
            if (it!=null){
                visited.add(it);
            }
        }

        for (Bucket<T> cur_bucket : visited){
            while(cur_bucket!=null){
                for (int j = 0 ; j < cur_bucket.size; j++){
                    if(cur_bucket.keys[j]==null)continue;
                    T key1 = convertValue(node.value,cur_bucket.keys[j]);
                    T key2 = convertValue(node.secondValue,cur_bucket.keys[j]);

                    if(compare(key1,cur_bucket.keys[j])<=0 && compare(key2,cur_bucket.keys[j])>=0){
                        results.add(cur_bucket.values[j]);
                    }

                }
                cur_bucket = cur_bucket.next;
            }
        }
        return results;
    }
    
    private T converT(String key){
        if(type == Integer.class || type==Double.class){
            return (T) Double.valueOf(key);
        }
        else if(type == LocalDate.class){
            return (T) LocalDate.parse(key,dateFormatter);
        }
        else if(type == String.class){
            return (T) key;
        }
        else{
            throw new IllegalArgumentException("Unsupported key type");
        }
    }
    @Override
    public List<Integer> evaluate(QueryNode node) {
        logger.info("Evaluating predicate using Hash index on attribute " + attribute + " for operator " + node.operator);

        // check if the attribute is valid to check rowIds
        if (!attribute.equals(node.attribute)) {
            throw new IllegalArgumentException("Invalid attribute: " + node.attribute);
        }

        switch (node.operator) {
            case EQUALS:
                return evaluateEquals(node);
            case LT:
                return evaluateLessThan(node);
            case GT:
                return evaluateGreaterThan(node);
            case RANGE:
                return evaluateRange(node);
            default:
                throw new IllegalArgumentException("Unsupported operator not supported at leaf node: " + node.operator);
        }
    }
    
   
    
    // @prism insertion with overflow if possible
    private void insertIntoBucket(Bucket<T> bucket, T key, int rowId){
        Bucket<T> cur_bucket = bucket;
        Bucket<T> prev_bucket = null;

        while(cur_bucket!=null){
            if(cur_bucket.size < BUCKET_SIZE ){
                cur_bucket.keys[cur_bucket.size] = key;
                cur_bucket.values[cur_bucket.size] = rowId;
                cur_bucket.size++;
                return;
            }
            prev_bucket = cur_bucket;
            cur_bucket = cur_bucket.next;
        }

        if (prev_bucket!=null){
            cur_bucket = new Bucket<>(prev_bucket.localDepth);
            prev_bucket.next = cur_bucket;
            cur_bucket.keys[cur_bucket.size] = key;
            cur_bucket.values[cur_bucket.size] = rowId;
            cur_bucket.size++;
            return;
        }
    }
    // @prism
    private void distribute_entries(Bucket<T> old_bucket,Bucket<T> new_bucket0,Bucket<T> new_bucket1,int old_localDepth){
        Bucket<T> cur_bucket = old_bucket;

        while(cur_bucket!=null){
            for (int i = 0; i < cur_bucket.size; i++){
                T key = cur_bucket.keys[i];
                int rowId = cur_bucket.values[i];
                int address_table_offset = getDirectoryIndex(key,globalDepth);

                if ((address_table_offset & (1 << old_localDepth)) == 0){
                    insertIntoBucket(new_bucket0,key,rowId);
                }else{
                    insertIntoBucket(new_bucket1,key,rowId);
                }
            }
            cur_bucket = cur_bucket.next;
        }
    }
     
    // @prism 
    private void update_directory(Bucket<T> new_bucket1,Bucket<T> new_bucket0,int localDepth,int address_table_offset){

        int original_mask = (1<<localDepth)-1;
        int original_offset = original_mask & address_table_offset;

        for (int i = 0 ; i < directory.length; i++){
            if((i & original_mask)!=original_offset)continue;

            if ((i & (1<<localDepth)) == 0){
                directory[i] = new_bucket0;
            }else{
                directory[i] = new_bucket1;
            }
        }

    }

    // @prism
    @SuppressWarnings("unchecked")
    private void expand_directory(){
        int new_directory_size = 1 <<(globalDepth+1);
        // needs to check @warning

        Bucket<T>[] new_directory = new Bucket[new_directory_size];

        for (int i = 0 ; i < directory.length ; i++){
            new_directory[i] = directory[i];
            new_directory[i+directory.length] = directory[i];
        }

        directory = new_directory;
        globalDepth++;
        
        return;
    }

    // @prism
    private void splitBucket(int address_table_offset){
        
        Bucket<T> old_bucket = directory[address_table_offset];
        int old_localDepth = old_bucket.getLocalDepth() ;

        if ( old_localDepth == globalDepth){
            expand_directory();
        }

        Bucket<T> new_bucket1 = new Bucket<>(old_localDepth+1);
        Bucket<T> new_bucket0 = new Bucket<>(old_localDepth+1);

        distribute_entries(old_bucket,new_bucket0,new_bucket1,old_localDepth);
        
        update_directory(new_bucket0,new_bucket1,old_localDepth,address_table_offset);



    }
    private Boolean duplicate_check(T key){
        int address_table_offset = getDirectoryIndex(key, globalDepth);
        Bucket<T> cur_bucket = directory[address_table_offset];
        while(cur_bucket!=null){
            for (int i = 0 ; i < cur_bucket.size; i++){
                if (cur_bucket.keys[i].equals(key)){
                    return true;
                }
            }
            cur_bucket = cur_bucket.next;
        }
        return false;
    }
    @Override
    public void insert(T key, int rowId) {
        int address_table_offset = getDirectoryIndex(key, globalDepth);
        Bucket<T> cur_bucket = directory[address_table_offset];
        // case0 : duplicate check
        if (duplicate_check(key)){
            insertIntoBucket(cur_bucket, key, rowId);
            return;
        }

        // case1 : Bucket is not full
        if (cur_bucket.size < BUCKET_SIZE){
            cur_bucket.keys[cur_bucket.size] = key;
            cur_bucket.values[cur_bucket.size] = rowId;
            cur_bucket.size++;
            return;
        }

        // case2 : space in overflow bucket
        Bucket<T> temp_bucket = cur_bucket;
        while(temp_bucket!=null){
            if(temp_bucket.size < BUCKET_SIZE){
                temp_bucket.keys[temp_bucket.size] = key;
                temp_bucket.values[temp_bucket.size] = rowId;
                temp_bucket.size++;
                return;
            }
            temp_bucket = temp_bucket.next;
        }
    
        // case3 : Bucket is full and no space in overflow Bucket
        splitBucket(address_table_offset);
        insert(key,rowId);
    }


    @Override
    public boolean delete(T key) {
        // TODO: (Bonus) Implement deletion logic with bucket merging and/or shrinking the address table
        return false;
    }


    @Override
    public List<Integer> search(T key) {
        int address_table_offset = getDirectoryIndex(key, globalDepth);

        Bucket<T> cur_bucket = directory[address_table_offset];
        List<Integer> results = new ArrayList<>();
        // System.out.println("with in seach in extendible");
        while (cur_bucket!=null){
            // System.out.println("one go ");
            // for(int i=0;i<cur_bucket.size;i++){
            //     System.out.println(cur_bucket.values[i]);
            // }
            for (int i = 0 ; i < cur_bucket.size; i++){
                try {
                    if(compare(cur_bucket.keys[i], key)==0){

                        results.add(cur_bucket.values[i]);
                    }
                    // if (cur_bucket.keys[i].equals(key)){
                    // }
                } catch (NullPointerException e) {
                    System.out.println("Null Pointer line 405 @raja Exception");
                    continue;
                }
                
            }
            cur_bucket = cur_bucket.next;
        }
        return results;
    }

    /**
     * Note: Do not remove this function!
     * @return
     */
    public int getGlobalDepth() {
        return globalDepth;
    }

    /**
     * Note: Do not remove this function!
     * @param bucketId
     * @return
     */
    public int getLocalDepth(int bucketId) {
        return directory[bucketId].localDepth;
    }

    /**
     * Note: Do not remove this function!
     * @return
     */
    public int getBucketCount() {
        return directory.length;
    }


    /**
     * Note: Do not remove this function!
     * @return
     */
    public Bucket<T>[] getBuckets() {
        return directory;
    }

    public void printTable() {
        System.out.println("========== Extendible Hashing Table ==========\n");
        System.out.println("Global Depth: " + globalDepth+"\n");
        System.out.println("Bucket Size: " + BUCKET_SIZE+"\n");
        System.out.println("Directory Size: " + directory.length+"\n");
        System.out.println("--------------------------------------------\n");
        
        for (int i = 0; i < directory.length; i++) {
            System.out.printf("Directory[%d]: ----------> \n", i);
            
            Bucket<T> current = directory[i];
            int overflowCount = 0;
            
            while (current != null) {
                System.out.printf("Bucket%d (local depth: %d): [", 
                                overflowCount, 
                                current.localDepth);
                
                // Print keys and values
                for (int j = 0; j < current.size; j++) {
                    System.out.printf("%s→%d", current.keys[j], current.values[j]);
                    if (j < current.size - 1) System.out.print(", ");
                }
                System.out.print("]\n");
                
                current = current.next;
                overflowCount++;
            }
            
            System.out.println();
        }
        System.out.println("============================================\n");
    }

    @Override
    public String prettyName() {
        return "Hash Index";
    }

}