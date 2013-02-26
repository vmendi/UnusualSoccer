package models;

import android.app.Activity;
import android.view.LayoutInflater;
import android.view.View;
import android.widget.Button;
import android.widget.TextView;
import com.example.R;
import controllers.AbstractController;

import java.lang.reflect.Array;
import java.lang.reflect.ParameterizedType;
import java.lang.reflect.Type;
import java.text.ParseException;
import java.util.*;

/**
 * Model for generic type of data.
 * It's a container class which contains other submodels needed for representation of main data.
 *
 * @author Yuri Samsoniuk
 */
public class GenericArgInfo extends ArgInfo {
    /**
     * Submodels
     */
    private ArrayList<ArgInfo> subModels;
    /**
     * Submodels data type
     */
    private Type componentType;
    /**
     * Mapping for abstract <code>List</code> and <code>Set</code> classes
     */
    private HashMap<Type, Type> collectionMapping;
    /**
     * Button of the main view.
     * Handles adding new model to the main model
     */
    private Button addItemButton;
    /**
     * Listener invoked on main view click
     * Collapses or expands model subviews
     */
    private View.OnClickListener mCollapseListener = new View.OnClickListener() {
        /**
         * Processes click event from the passed view
         * @param view view generated an event
         */
        public void onClick(View view) {
            ArrayList<View> subViews = getSubViews(view);
            if (!subViews.isEmpty()) {
                int visibility = subViews.get(0).getVisibility() == View.VISIBLE
                        ? View.GONE : View.VISIBLE;
                for (View subView : subViews) {
                    subView.setVisibility(visibility);
                }
            }
        }
    };
    /**
     * Listener invoked on addItemButton
     * Adds new submodel
     */
    private View.OnClickListener mAddItemListener = new View.OnClickListener() {
        /**
         * Processes click event from the passed view
         * @param view view generated an event
         */
        public void onClick(View view) {
            ArgInfo newModel = controller.getModel(view.getPaddingLeft() + padding, componentType);
            newModel.createView("[" + views.size() + "]");
            subModels.add(newModel);
            View newView = newModel.getMainView();
            views.add(newView);
            ArrayList<View> viewsToAdd = new ArrayList<View>();
            viewsToAdd.add(newView);
            ArrayList<View> subViews = newModel.getSubViews(newView);
            if(subViews != null) {
                viewsToAdd.addAll(subViews);
            }
            controller.addItems(viewsToAdd.toArray(new View[]{}));
        }
    };

    /**
     * Constructor of the model
     *
     * @param type       of data represented by the model
     * @param activity   application activity
     * @param controller handling controller
     * @param padding    padding of the main view
     */
    public GenericArgInfo(Type type, Activity activity, AbstractController controller, int padding) {
        super(type, activity, controller, padding);
        subModels = new ArrayList<ArgInfo>();
        componentType = ((ParameterizedType) type).getActualTypeArguments()[0];
        collectionMapping = new HashMap<Type, Type>();
        collectionMapping.put(Set.class, HashSet.class);
        collectionMapping.put(List.class, ArrayList.class);
    }

    @Override
    public void createView(String name) {
        LayoutInflater inflater = LayoutInflater.from(activity);
        view = inflater.inflate(R.layout.expandable_list_view, null);
        TextView nameView = ((TextView) view.findViewById(R.id.name));
        nameView.setText(name);
        nameView.setPadding(nameView.getPaddingLeft() + padding, nameView.getPaddingTop(),
                nameView.getPaddingRight(), nameView.getPaddingBottom());
        Type rawType = ((ParameterizedType) type).getRawType();
        ((TextView) view.findViewById(R.id.type)).setText(((Class) rawType).getSimpleName());
        addItemButton = (Button) view.findViewById(R.id.add_item_button);
        if (componentType instanceof ParameterizedType) {
            String subTypeName = ((ParameterizedType) componentType).getRawType().toString();
            String typeStr = subTypeName.substring(subTypeName.lastIndexOf(".") + 1);
            addItemButton.setText("Add (" + typeStr + ")");
        } else {
            addItemButton.setText("Add (" + ((Class) componentType).getSimpleName() + ")");
        }
        addItemButton.setOnClickListener(mAddItemListener);
        view.setOnClickListener(mCollapseListener);
    }

    @Override
    public ArrayList<View> getSubViews(View view) {
        ArrayList<View> subViews = new ArrayList<View>();
        ArrayList<View> viewSubViews;
        if (view == this.view) {
            for (ArgInfo model : subModels) {
                View mainView = model.getMainView();
                subViews.add(mainView);
                viewSubViews = model.getSubViews(mainView);
                if (viewSubViews != null)
                    subViews.addAll(viewSubViews);
            }
        } else {
            for (ArgInfo model : subModels) {
                if (model.getPosition(view) != -1) {
                    View mainView = model.getMainView();
                    viewSubViews = model.getSubViews(mainView);
                    if (viewSubViews != null)
                        subViews.addAll(viewSubViews);
                }
            }
        }
        return subViews;
    }

    @Override
    public Class getModelClass(View view) {
        Class clazz = super.getModelClass(view);
        if (clazz == null) {
            for (ArgInfo model : subModels) {
                clazz = model.getModelClass(view);
                if (clazz != null) {
                    return clazz;
                }
            }
        }
        return clazz;
    }

    @Override
    public int getPosition(View view) {
        if (view == this.view)
            return 0;
        int viewPos;
        int rowsBeforeView = 1;
        for (ArgInfo subModel : subModels) {
            viewPos = subModel.getPosition(view);
            if (viewPos != -1) {
                viewPos += rowsBeforeView;
                return viewPos;
            } else {
                rowsBeforeView += subModel.getRowsCount();
            }
        }
        return -1;
    }

    @Override
    public View addView(View view) {
        if (view == this.view) {
            int newPaddin = view.getPaddingLeft() + padding;
            ArgInfo model = controller.getModel(newPaddin, componentType);
            model.createView("[" + views.size() + "]");
            subModels.add(model);
            View subView = model.getMainView();
            views.add(subView);
            return subView;
        } else {
            View subView = null;
            for (ArgInfo model : subModels) {
                if ((subView = model.addView(view)) != null) {
                    return subView;
                }
            }
        }
        return null;
    }

    @Override
    public int getRowsCount() {
        int rows = 1;
        for (ArgInfo model : subModels) {
            rows += model.getRowsCount();
        }
        return rows;
    }

    @Override
    public Object getValue() throws ParseException {
        Collection result = null;
        Type rawType = ((ParameterizedType) type).getRawType();
        try {
            if (List.class.isAssignableFrom((Class<?>) (rawType))) {
                result = (Collection) ((Class<?>) collectionMapping.get(List.class)).newInstance();
            } else if (Set.class.isAssignableFrom((Class<?>) rawType)) {
                result = (Collection) ((Class<?>) collectionMapping.get(Set.class)).newInstance();
            }
            for (ArgInfo subModel : subModels) {
                result.add(subModel.getValue());
            }
        } catch (InstantiationException e) {
            e.printStackTrace();  //To change body of catch statement use File | Settings | File Templates.
        } catch (IllegalAccessException e) {
            e.printStackTrace();  //To change body of catch statement use File | Settings | File Templates.
        }
        return result;
    }

    @Override
    public void setValue(Object value) {
        Object arrayValue = ((Collection) value).toArray();
        int length = Array.getLength(arrayValue);
        addItemButton.setText("Collapse");
        addItemButton.setClickable(false);
        view.setClickable(true);
        for (int i = 0; i < length; i++) {
            ArgInfo model = controller.getModel(view.getPaddingLeft() + padding,
                    ((ParameterizedType) type).getActualTypeArguments()[0]);
            model.createView("[" + i + "]");
            model.setValue(Array.get(arrayValue, i));
            views.add(model.getMainView());
            subModels.add(model);
        }
    }

    @Override
    public int getInputType(View view) {
        int inputType = super.getInputType(view);
        if (view == this.view) {
            return inputType;
        }
        int position;
        for (ArgInfo model : subModels) {
            position = model.getPosition(view);
            if (position != -1) {
                inputType = model.getInputType(view);
            }
        }
        return inputType;
    }
}
