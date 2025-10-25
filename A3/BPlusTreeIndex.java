package in.ac.iitd.db362.index.bplustree;

import in.ac.iitd.db362.index.Index;
import in.ac.iitd.db362.parser.QueryNode;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;
import java.time.format.DateTimeFormatter;

/**
 * Starter code for BPlusTree Implementation
 * @param <T> The type of the key.
*/

public class BPlusTreeIndex<T> implements Index<T> {

    protected static final Logger logger = LogManager.getLogger();

    private final Class<T> type;

    // Note: Do not rename this variable; the test cases will set this when testing. You can however initialize it with a
    // different value for testing your code.
    public static int ORDER = 10;

    // The attribute being indexed
    private String attribute;

    // Our Values are all integers (rowIds)
    private Node<T, Integer> root;
    private final int order; // Maximum children per node

    DateTimeFormatter dateFormatter = DateTimeFormatter.ISO_LOCAL_DATE;
    
    /** Constructor to initialize the B+ Tree with a given order */
    public BPlusTreeIndex(Class<T> type, String attribute) {
        this.type = type;
        this.attribute = attribute;
        this.order = ORDER;
        this.root = new Node<>();
        this.root.isLeaf = true;
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

    private List<Integer> lessThanQuery(T key){
        Node<T,Integer> node = root;
        while(!node.isLeaf) {
            node = node.getChild(0);
        }
        // System.out.println("printing tree for me");
        // PrintTree(root);
        // Node<T,Integer> cur=node;
        // while(cur!=null){
        //     System.out.println(node.getKeys());
        //     cur=cur.next;
        // }

        List<Integer> result = new ArrayList<>();
        boolean brk=false;

        while(node != null){
            // System.out.println("checkpoint 11 "+node.keys);
            try
            {    for(int i = 0; i < node.getKeys().size(); i++) {
                    if(compare(node.getKeys().get(i), key) < 0) {
                        result.addAll(Addvalues(node, i));
                    }else{
                        brk=true;
                        break;
                    }
                }
            }catch(Exception e){
                System.out.println(" checkpoint 13"+e.getMessage());
            }
            if(brk){
                break;
            }
            node = node.next;
            // if (node != null) {
            //     System.out.println("Moving to next node: " + node.keys);
            // }
        }
        return result;
    }
    private List<Integer> greaterThanQuery(T key){
        Node<T,Integer> node = root;

        while(!node.isLeaf) {
            int i = 0;
            while(i < node.getKeys().size() && compare(node.getKeys().get(i),key) <= 0) {
                i++;
            }
            node = node.getChild(i);
        }

        List<Integer> result = new ArrayList<>();

        while(node != null){
            for(int i = 0; i < node.getKeys().size(); i++) {
                if(compare(node.getKeys().get(i), key) > 0) {
                    result.addAll(Addvalues(node, i));
                }
            }
            node = node.next;
        }
        return result;
    }
    @Override
    public List<Integer> evaluate(QueryNode node) {
        // System.out.println("checkpoint 5 = " + node.attribute);
        logger.info("Evaluating predicate using B+ Tree index on attribute " + attribute + " for operator " + node.operator);
        System.out.println(attribute);
        // if(node.attribute.equals(attribute)) {
        //     System.out.println("mismatched checkpoint 5.1 = " + node.attribute);
        //     return new ArrayList<>();
        // }
        T key = converT(node.value);

        switch(node.operator){
            case EQUALS:
                // System.out.println("EQUALS checkpoint 6 = " + key);

                return search(key);
            case LT:
                // System.out.println("checkpoint 7 : ");
                List<Integer> a = lessThanQuery(key); 
                // System.out.println("checkpoint 12");
                return a;
            case GT:
                List<Integer> b = greaterThanQuery(key); 
                // System.out.println("checkpoint 7 : "+b);
                return b;
            case RANGE:
                // System.out.println("checkpoint 18 : ");
                return rangeQuery(key, false,converT(node.secondValue), false);
            default:
                logger.warn("Unsupported operator: " + node.operator);
                return new ArrayList<>();
        }
    }

    private void insertToLeaf(Node<T, Integer> leaf, T key, int rowId) {
        if(leaf==null){
            throw new IllegalArgumentException("Leaf cannot be null");
        }
        if(leaf.getKeys()==null){
            leaf.keys = new ArrayList<>();
            leaf.values = new ArrayList<>();
            leaf.children = new ArrayList<>();
        }

        try {
            int i = 0;
            if(!leaf.getKeys().isEmpty()){
                while(i < leaf.getKeys().size() && compare(leaf.getKeys().get(i),key) < 0) {
                    i++;
                }
            }
            leaf.getKeys().add(i, key);
            Node<T,Integer> child = new Node<>();
            child.values = new ArrayList<>();
            child.getValues().add(0,rowId);
            leaf.children.add(i,child);

        }catch (Exception e){
            System.out.println("Error inserting key in leaf: " + key + " | Exception: " + e.getClass().getSimpleName() + ": " + e.getMessage());
            e.printStackTrace();
        }
        // System.out.println("all keys of leaf "+leaf.getKeys());
        return;
    }

    private void splitNode(Node<T,Integer> node, Node<T,Integer> parent) {
        Node<T,Integer> newNode = new Node<>();
        newNode.children = new ArrayList<>();
        newNode.keys = new ArrayList<>();
        newNode.values = new ArrayList<>();

        
        newNode.isLeaf = node.isLeaf;
        int mid = (node.getKeys().size())/2;
        boolean isparentnull=false;

        if(parent == null){
            isparentnull = true;
        }

        // System.out.println("splitting node with in split func " + node.getKeys());

        if(parent == null) {
            parent = new Node<>();
            parent.isLeaf = false;
            parent.keys = new ArrayList<>();
            parent.children = new ArrayList<>();
            parent.values = new ArrayList<>();

            root = parent;
        }
        if(node.isLeaf){

            // System.out.println("size of nodes "+ mid);;

            newNode.keys = new ArrayList<>(node.getKeys().subList(mid, node.getKeys().size()));
            newNode.children = new ArrayList<>(node.children.subList(mid, node.getKeys().size()));

            node.keys = new ArrayList<>(node.getKeys().subList(0, mid));
            node.children = new ArrayList<>(node.children.subList(0, mid));
            
            newNode.next = node.next;
            node.next = newNode;
            // System.out.println("splitting node with in split func " + node.keys);
            // System.out.println("splitting node with in split func " + newNode.keys);
            try{
                if(node.next==null){
                    System.out.println("not next available");
                }
    
            }catch(Exception e){
                System.out.println(" erroro in split "+e.getMessage()+ e.getClass().getSimpleName());
            }
            if (newNode.keys.isEmpty()) {
                System.out.println("Error: newNode.keys is empty after split");
                return; // Handle appropriately
            }
            
            T key = newNode.getKeys().get(0);
            // System.out.println(key);
            // System.out.println("\n\n");
            // Handling parent pointers
            if(isparentnull){
                parent.children.add(node);
                parent.children.add(newNode);
                parent.getKeys().add(key);
            }else{
                int i = 0;
                while(i < parent.getKeys().size() && compare(parent.getKeys().get(i),key) < 0) {
                    i++;
                }
                parent.getKeys().add(i, key);
                parent.getChildren().add(i+1, newNode);
            }
            

        }else{
            newNode.children = new ArrayList<>(node.getChildren().subList(mid+1, node.getChildren().size()));
            newNode.keys = new ArrayList<>(node.getKeys().subList(mid+1, node.getKeys().size()));

            T key = node.getKeys().get(mid);

            node.keys = new ArrayList<>(node.getKeys().subList(0, mid));
            node.children = new ArrayList<>(node.getChildren().subList(0, mid+1));

            if(isparentnull){
                parent.children.add(node);
                parent.children.add(newNode);
                parent.getKeys().add(key);
            }else{
                int i = 0;
                while(i < parent.getKeys().size() && compare(parent.getKeys().get(i),key) < 0) {
                    i++;
                }
                parent.getKeys().add(i, key);
                parent.getChildren().add(i+1, newNode);
            }
            // Handling parent pointers

        }
    }

    private void Insertionfunc(Node<T,Integer> node,Node<T,Integer> parent,T key,int rowId){
        if(node.isLeaf){
            // System.out.println("inserting to leaf = " + key);
            insertToLeaf(node, key, rowId);
            // System.out.println("out of leaf but here to leaf = " + key);
        }
        else{
            int i = 0;
            while(i < node.getKeys().size() && compare(node.getKeys().get(i),key) <= 0) {
                i++;
            }
            Insertionfunc(node.getChild(i),node, key, rowId);
        }
        
        if(node.getKeys().size() >= order) {
            // System.out.println("splitting node = " + key);
            splitNode(node,parent);
        }

        // System.out.println("out of insertion in recursive function = " + key);
        // if(node.getKeys()!=null){
        //     System.out.println("keys of node = " + node.getKeys());
        // }
        // if(parent !=null && parent.getChildren()!=null){
        //     System.out.println("keys of parent = " + parent.getKeys());
        // }
        // System.out.println("out of insertion in recursive function = " + key);
        
    }

    private Node<T,Integer> duplicate_check(T key){
        Node<T,Integer> node = root;
        if(root==null) return null;
        while(!node.isLeaf) {
            int i = 0;
            while(i < node.getKeys().size() && compare(node.getKeys().get(i),key) <= 0) {
                i++;
            }
            node = node.getChild(i);
        }
        if(node==null) return null;

        if(node.getKeys()==null) return null;
        // System.out.println("checkpoint 1");
        try{
            for(int i=0;i<node.getKeys().size();i++){
                if(compare(node.getKeys().get(i), key)==0){
                    return node.children.get(i);
                }
            }
        }catch(Exception e){
            System.out.println("exec duplicate  "+e.getMessage());
        }
        // System.out.println("checkpoint 2");
        return null;
    }
    @Override
    public void insert(T key, int rowId) {

        // System.out.println("Insert + key = " + key);
        Node<T,Integer> child=null;
        try{
            child  = duplicate_check(key);
            
        }catch(Exception e){
            System.out.println("Error inserting duplicate : " + e.getMessage() );
        }
        // if(rowId==187){
        //     System.out.println("@@ "+key);
        // }
        if(child!=null){
            child.getValues().add(rowId);
            // System.out.println(key+" keys and rowids "+child.getValues());
            return;
        }
        // if(rowId==187){
        //     System.out.println("@@ "+key);
        // }
    
        Insertionfunc(getRoot(),null, key, rowId);
        
        
        // if (key != null && key.equals(200)) {
            // System.out.println("start complete tree");
            // PrintTree(getRoot());
            // // // System.out.println("Insertion done " + key);
            // System.out.println("\n\n");
        // }
    }
    private List<Integer> Addvalues(Node<T,Integer> node,int i){
        // System.out.println("checkpoint 8");
        if(i<node.children.size()){
            // System.out.println(node.children.get(i).getValues());
            return node.children.get(i).getValues();
        }
        // System.out.println("goind out of bound");
        return new ArrayList<>();
        
    }
    private void PrintTree(Node<T,Integer> node){
        if(node == null){
            return;
        }
        if(node.isLeaf){
            System.out.println("this leaf ");
            for(int i=0;i<node.getKeys().size();i++){
                System.out.println(" Key "+ node.getKeys().get(i) + " ids : "+node.children.get(i).getValues());
            }
            return;
        }else{
            System.out.println("Internal Node: "+node.getKeys());
        }
        if(node.getChildren() == null){
            return;
        }
        for(Node<T,Integer> child: node.getChildren()){
            PrintTree(child);
        }
    }

    @Override
    public boolean delete(T key) {
        //TODO: Bonus
        return false;
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

    @Override
    public List<Integer> search(T key) {
        Node<T,Integer> node = root;
        while(!node.isLeaf) {
            int i = 0;
            while(i < node.getKeys().size() && compare(node.getKeys().get(i),key) < 0) {
                i++;
            }
            node = node.getChild(i);
        }
        List<Integer> result = new ArrayList<>();
        // System.out.println("checkpoint 16 "+node.getKeys());
        for(int i=0;i<node.getKeys().size();i++){
            if(compare(node.getKeys().get(i),key)==0){
                result.addAll(Addvalues(node,i));
            }
        }
        return result;
    }

    /**
     * Function that evaluates a range query and returns a list of rowIds.
     * e.g., 50 < x <=75, then function can be called as rangeQuery(50, false, 75, true)
     * @param startKey
     * @param startInclusive
     * @param endKey
     * @param endInclusive
     * @return all rowIds that satisfy the range predicate
     */
    List<Integer> rangeQuery(T startKey, boolean startInclusive, T endKey, boolean endInclusive) {
        Node<T,Integer> node = root;
        while(!node.isLeaf) {
            int i = 0;
            while(i < node.getKeys().size() && compare(node.getKeys().get(i),startKey) <= 0) {
                i++;
            }
            node = node.getChild(i);
        }
        List<Integer> result = new ArrayList<>();
        // System.out.println("checkpoint 19 "+node.keys);
        int i = 0;
        while(node!=null){
            while(i < node.getKeys().size() && compare(node.getKeys().get(i),startKey) < 0) {
                i++;
            }
            // System.out.println("checkpoint 19.1 "+result);
            if( i < node.getKeys().size() && compare(node.getKeys().get(i),startKey) == 0 && startInclusive) {
                result.addAll(Addvalues(node, i));
                i++;
            }
            // System.out.println("checkpoint 19.2 "+result);
            while(i < node.getKeys().size() && compare(node.getKeys().get(i),endKey) < 0) {
                result.addAll(Addvalues(node, i));
                i++;
            }
            // System.out.println("checkpoint 19.3 "+result);
            if(i < node.getKeys().size() && compare(node.getKeys().get(i),endKey) == 0 && endInclusive) {
                result.addAll(Addvalues(node, i));
                i++;
            }
            if(i < node.getKeys().size() && compare(node.getKeys().get(i),endKey) > 0) {
                break;
            }
            // System.out.println("checkpoint 19.4 "+result);
            node = node.next;
            i = 0;
        }
        //Note: When searching, use Node's getChild() and getNext() methods. Some test cases may fail otherwise!
        return result;
    }

    /**
     * Traverse leaf nodes and collect all keys in sorted order
     * @return all Keys
     */
    public List<T> getAllKeys() {
        List<T> keys = new ArrayList<>();
        Node<T, Integer> node = getRoot();

        while(!node.isLeaf) {
            node = node.getChild(0);
        }
        while(node != null){
            for(int i=0;i<node.getKeys().size();i++){
                keys.add(node.getKeys().get(i));
            }
            node = node.next;
        }
        return keys;
    }

    /**
     * Compute tree height by traversing from root to leaf
     * @return Height of the b+ tree
     */
    public int getHeight() {

        int height = 0;
        Node<T, Integer> node = getRoot();

        while(root != null) {
            if(node.isLeaf) {
                break;
            }
            height++;
            node = node.getChild(0);
        }

        return height;
    }

    /**
     * Funtion that returns the order of the BPlusTree
     * Note: Do not remove this function!
     * @return
     */
    public int getOrder() {
        return order;
    }


    public String getAttribute() {
        return attribute;
    }

    public Node<T, Integer> getRoot() {
        return root;
    }


    @Override
    public String prettyName() {
        return "B+Tree Index";
    }
}
