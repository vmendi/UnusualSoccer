package models;

import android.app.Activity;
import android.view.LayoutInflater;
import android.view.View;
import android.widget.Button;
import android.widget.TextView;
import com.example.R;
import controllers.AbstractController;

import java.lang.reflect.ParameterizedType;
import java.lang.reflect.Type;
import java.text.ParseException;
import java.util.*;

/**
 * Model for <code>Map</code> type of data.
 *
 * @author Yuri Samsoniuk
 */
public class MapArgInfo extends ArgInfo {
    /**
     * Submodels
     */
    private ArrayList<ArgInfo> subModels;
    /**
     * Button of the main view.
     * Handles adding new model to the main model
     */
    private Button addItemButton;

    /**
     * Key/Value types
     */
    private Type[] componentTypes;
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
            View newView = null;
            ArgInfo newModel = new MapEntryArgInfo(componentTypes, activity, controller, view.getPaddingLeft() + padding);
            newModel.createView("");
            subModels.add(newModel);
            newView = newModel.getMainView();
            views.add(newView);
            controller.addItems(newView);
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
    public MapArgInfo(Type type, Activity activity, AbstractController controller, int padding) {
        super(type, activity, controller, padding);
        subModels = new ArrayList<ArgInfo>();
    }

    @Override
    public void createView(String name) {
        LayoutInflater inflater = LayoutInflater.from(activity);
        view = inflater.inflate(R.layout.expandable_list_view, null);
        TextView nameView = ((TextView) view.findViewById(R.id.name));
        nameView.setText(name);
        nameView.setPadding(nameView.getPaddingLeft() + padding, nameView.getPaddingTop(),
                nameView.getPaddingRight(), nameView.getPaddingBottom());
        Type rawType;
        if (type instanceof ParameterizedType) {
            rawType = ((ParameterizedType) type).getRawType();
            componentTypes = ((ParameterizedType) type).getActualTypeArguments();
        } else {
            rawType = type;
            componentTypes = new Type[]{String.class, String.class};
        }
        ((TextView) view.findViewById(R.id.type)).setText(((Class) rawType).getSimpleName());
        addItemButton = (Button) view.findViewById(R.id.add_item_button);
        addItemButton.setText("Add entry");
        if (componentTypes[1] instanceof ParameterizedType) {
            String subTypeName = ((ParameterizedType) componentTypes[1]).getRawType().toString();
            String typeStr = subTypeName.substring(subTypeName.lastIndexOf(".") + 1);
            addItemButton.setText("Add (" + typeStr + ")");
        } else {
            addItemButton.setText("Add (" + ((Class) componentTypes[1]).getSimpleName() + ")");
        }
        addItemButton.setOnClickListener(mAddItemListener);
        view.setOnClickListener(mCollapseListener);
    }

    @Override
    public Object getValue() throws ParseException {
        Map result = null;
        Class rawType;
        if (type instanceof ParameterizedType) {
            rawType = (Class) ((ParameterizedType) type).getRawType();
        } else {
            rawType = (Class) type;
        }
        try {
            if (rawType.isInterface()) {
                result = HashMap.class.newInstance();
            } else {
                result = (Map) rawType.newInstance();
            }
            for (ArgInfo model : subModels) {
                Map.Entry entry = (Map.Entry) model.getValue();
                result.put(entry.getKey(), entry.getValue());
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
        Set entrySet = ((Map) value).entrySet();
        addItemButton.setText("Collapse");
        addItemButton.setClickable(false);
        view.setClickable(true);
        for (Object entry : entrySet) {
            ArgInfo model = new MapEntryArgInfo(componentTypes, activity, controller, view.getPaddingLeft() + padding);
            model.createView(null);
            model.setValue(entry);
            views.add(model.getMainView());
            subModels.add(model);
        }
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
    public int getRowsCount() {
        int rows = 1;
        for (ArgInfo model : subModels) {
            rows += model.getRowsCount();
        }
        return rows;
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

    /**
     * Model for <code>Map.Entry</code> type. Used by <code>MapArgInfo</code>
     *
     * @author Yuri Samsoniuk
     */
    private class MapEntryArgInfo extends ArgInfo {
        /**
         * Key/Value types
         */
        private Type[] types;
        /**
         * Key model
         */
        private ArgInfo keyModel;
        /**
         * Value model
         */
        private ArgInfo valueModel;
        /**
         * Key view
         */
        private TextView keyView;
        /**
         * Value view
         */
        private TextView valueView;

        /**
         * Constructor of the model
         *
         * @param types      type of data represented by the model
         * @param activity   application activity
         * @param controller handling controller
         * @param padding    padding of the main view
         */
        public MapEntryArgInfo(Type[] types, Activity activity, AbstractController controller, int padding) {
            super(null, activity, controller, padding);
            this.types = types;
        }

        @Override
        public void createView(String name) {
            LayoutInflater inflater = LayoutInflater.from(activity);
            view = inflater.inflate(R.layout.map_entry_view, null);
            keyView = ((TextView) view.findViewById(R.id.key));
            keyView.setPadding(keyView.getPaddingLeft() + padding, keyView.getPaddingTop(),
                    keyView.getPaddingRight(), keyView.getPaddingBottom());
            keyView.setOnClickListener(controller.getListener());
            keyModel = controller.getModel(view.getPaddingLeft() + padding, types[0]);
            keyModel.createView("Key");
            valueView = (TextView) view.findViewById(R.id.value);
            valueView.setOnClickListener(controller.getListener());
            valueModel = controller.getModel(view.getPaddingLeft() + padding, types[1]);
            valueModel.createView("Value");
            ((TextView) view.findViewById(R.id.type)).setText(((Class<?>) types[1]).getSimpleName());
        }

        @Override
        public Object getValue() throws ParseException {
            keyModel.setValue(keyView.getText());
            valueModel.setValue(valueView.getText());
            return new AbstractMap.SimpleEntry(keyModel.getValue(), valueModel.getValue());
        }

        @Override
        public void setValue(Object value) {
            keyView.setHint(R.string.empty);
            keyModel.setValue(((Map.Entry) value).getKey());
            keyView.setText(keyModel.getStringValue());
            keyView.setClickable(false);
            valueView.setHint(R.string.empty);
            valueModel.setValue(((Map.Entry) value).getValue());
            valueView.setText(valueModel.getStringValue());
            valueView.setClickable(false);
        }

        @Override
        public int getInputType(View view) {
            if (view == keyView) {
                return keyModel.getInputType(view);
            } else {
                return valueModel.getInputType(view);
            }
        }

        @Override
        public Class getModelClass(View view) {
            if (view == keyView) {
                return keyModel.getClass();
            } else if (view == valueView) {
                return valueModel.getClass();
            } else {
                return super.getModelClass(view);
            }
        }

        @Override
        public int getPosition(View view) {
            if (view == this.view || view == keyView || view == valueView) {
                return 0;
            }
            return -1;
        }
    }
}
