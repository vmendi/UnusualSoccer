package models;

import android.app.Activity;
import android.view.LayoutInflater;
import android.view.View;
import android.widget.Button;
import android.widget.TextView;
import com.example.R;
import controllers.AbstractController;

import java.lang.reflect.Array;
import java.lang.reflect.Type;
import java.text.ParseException;
import java.util.*;

/**
 * Model for <code>Array</code> type of data.
 * It's a container class which contains other submodels needed for representation of main data.
 *
 * @author Yuri Samsoniuk
 */
public class ArrayArgInfo extends ArgInfo {
    /**
     * Submodels
     */
    private ArrayList<ArgInfo> subModels;
    /**
     * Submodels data type
     */
    private Type componentType;
    /**
     * Mapping for non-generic <code>List</code> and <code>Set</code> classes
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
    public ArrayArgInfo(Type type, Activity activity, AbstractController controller, int padding) {
        super(type, activity, controller, padding);
        subModels = new ArrayList<ArgInfo>();
        componentType = ((Class) type).getComponentType();
        if (componentType == null) {
            componentType = String.class;
        }
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
        ((TextView) view.findViewById(R.id.type)).setText(((Class) type).getSimpleName());
        addItemButton = (Button) view.findViewById(R.id.add_item_button);
        addItemButton.setText("Add (" + ((Class<?>) componentType).getSimpleName() + ")");
        addItemButton.setOnClickListener(mAddItemListener);
        view.setOnClickListener(mCollapseListener);
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
    public int getRowsCount() {
        int rows = 1;
        for (ArgInfo model : subModels) {
            rows += model.getRowsCount();
        }
        return rows;
    }

    @Override
    public View addView(View view) {
        View newView = null;
        if (view == this.view) {
            ArgInfo model = controller.getModel(view.getPaddingLeft() + padding, componentType);
            model.createView("[" + views.size() + "]");
            subModels.add(model);
            newView = model.getMainView();
            views.add(newView);
        } else {
            for (ArgInfo model : subModels) {
                if ((newView = model.addView(view)) != null) {
                    break;
                }
            }
        }
        return newView;
    }

    @Override
    public Object getValue() throws ParseException {
        Object result = null;
        if (((Class<?>) type).isArray()) {
            result = Array.newInstance((Class<?>) componentType, subModels.size());
            for (int i = 0; i < subModels.size(); i++) {
                Array.set(result, i, subModels.get(i).getValue());
            }
        } else {
            try {
                if (List.class.isAssignableFrom((Class<?>) type)) {
                    result = ((Class<?>) collectionMapping.get(List.class)).newInstance();
                } else if (Set.class.isAssignableFrom((Class<?>) type)) {
                    result = ((Class<?>) collectionMapping.get(Set.class)).newInstance();
                }
                for (ArgInfo subModel : subModels) {
                    ((Collection) result).add(subModel.getValue());
                }
                return result;
            } catch (InstantiationException e) {
                e.printStackTrace();  //To change body of catch statement use File | Settings | File Templates.
            } catch (IllegalAccessException e) {
                e.printStackTrace();  //To change body of catch statement use File | Settings | File Templates.
            }
        }
        return result;
    }

    @Override
    public void setValue(Object value) {
        int length;
        Object realValue = value;
        if (((Class<?>) type).isArray()) {
            length = Array.getLength(value);
        } else {
            length = ((Collection) value).size();
            realValue = ((Collection) value).toArray();
        }
        addItemButton.setText("Collapse");
        view.findViewById(R.id.add_item_button).setClickable(false);
        view.setClickable(true);
        for (int i = 0; i < length; i++) {
            Object elementValue = Array.get(realValue, i);
            ArgInfo model = controller.getModel(view.getPaddingLeft() + padding, elementValue.getClass());
            model.createView("[" + i + "]");
            model.setValue(elementValue);
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
