package models;

import java.lang.reflect.Method;
import java.lang.reflect.Modifier;
import java.lang.reflect.Type;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * Main model. Contains inspecting class, its methods, selected method, etc.
 *
 * @author Yuri Samsoniuk
 */
public class AppModel {
    /**
     * Class for class name
     */
    private Class clazz;
    /**
     * Inspecting class methods
     */
    private Method[] methods;
    /**
     * Selected method for invocation
     */
    public Method currentMethod = null;
    /**
     * Selected method invocation result type
     */
    public Type methodInvokationResultType = null;
    /**
     * Selected method invocation result
     */
    public Object methodInvokationResult = null;
    /**
     * Invocation result error message
     */
    public String errorMessage = null;
    /**
     * Invoking method arguments
     */
    public Object[] methodArguments = null;
    /**
     * WebORB Endpoint URL
     *
     * @see #loadProperties()
     * @see #saveProperties()
     */
    public String WebORBURL;
    /**
     * Invoking class name
     */
    public String invokingServiceClass = "weborb.examples.TestService";
    /**
     * Singleton model object
     */
    private static AppModel model = new AppModel();

    /**
     * Returns instance of the model
     *
     * @return model instance
     */
    public static AppModel getInstance() {
        return model;
    }

    /**
     * Constructor of the model. Called only once.
     */
    private AppModel() {
        try {
            clazz = Class.forName(invokingServiceClass);
            methods = clazz.getDeclaredMethods();
        } catch (ClassNotFoundException ignored) {
        }
        loadProperties();
    }

    /**
     * Loads WebORB Endpoint URL from system properties, if no such property, then sets to sample
     */
    private void loadProperties() {
        WebORBURL = System.getProperty("WebORBURL");
        if (WebORBURL == null) {
            WebORBURL = "http://10.0.2.2:8080/console/weborb.wo";
        }
    }

    /**
     * Saves WebORB Endpoint URL to system properties
     */
    public void saveProperties() {
        System.setProperty("WebORBURL", WebORBURL);
    }

    /**
     * Returns description(method names and signatures) of the invoking class methods
     *
     * @param methodNameKey        key for method name
     * @param methodDescriptionKey key for description(signature)
     * @return description of the invoking class methods
     */
    public List<Map<String, String>> getMethodDescriptionList(String methodNameKey, String methodDescriptionKey) {
        List<Map<String, String>> methodDescriptionList = new ArrayList<Map<String, String>>();
        for (Method m : methods) {
            if (Modifier.isPublic(m.getModifiers())) {
                Map<String, String> map = new HashMap<String, String>();
                map.put(methodNameKey, m.getName());
                String description = m.getReturnType().getSimpleName() + " " + m.getName() + "(";
                Class[] parameterTypes = m.getParameterTypes();
                for (int j = 0; j < parameterTypes.length - 1; j++) {
                    if (j == 0)
                        description += (parameterTypes[j].getSimpleName() + " arg" + j);
                    else
                        description += (", " + parameterTypes[j].getSimpleName() + " arg" + j);
                }
                description += ")";
                map.put(methodDescriptionKey, description);
                methodDescriptionList.add(map);
            }
        }

        return methodDescriptionList;
    }

    /**
     * Sets invoking method
     *
     * @param index index of method in method list
     */
    public void setCurrentMethod(int index) {
        currentMethod = methods[index];
    }
}
