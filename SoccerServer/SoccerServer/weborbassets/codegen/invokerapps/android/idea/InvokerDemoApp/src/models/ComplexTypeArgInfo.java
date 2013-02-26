package models;

import android.app.Activity;
import android.view.LayoutInflater;
import android.view.View;
import android.widget.Button;
import android.widget.TextView;
import com.example.R;
import controllers.AbstractController;

import java.lang.reflect.*;
import java.text.ParseException;
import java.util.ArrayList;
import java.util.HashMap;

/**
 * Model for complex data type.
 * It's a container class which contains other submodels needed for representation of main data.
 *
 * @author Yuri Samsoniuk
 */
public class ComplexTypeArgInfo extends ArgInfo {
    /**
     * Submodels
     * Inner data of the complex type
     */
    private ArrayList<ArgInfo> subModels;
    /**
     * Mapping for the fields of the main type and models representing field
     */
    private HashMap<ArgInfo, Field> modelToFieldMap;
    /**
     * Button of the main view.
     * Handles collapsing/expanding of the subviews
     */
    private Button collapseButton;
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
     * Constructor of the model
     *
     * @param type       of data represented by the model
     * @param activity    application activity
     * @param controller handling controller
     * @param padding    padding of the main view
     */
    public ComplexTypeArgInfo(Type type, Activity activity, AbstractController controller, int padding) {
        super(type, activity, controller, padding);
        subModels = new ArrayList<ArgInfo>();
        modelToFieldMap = new HashMap<ArgInfo, Field>();
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
        collapseButton = (Button) view.findViewById(R.id.add_item_button);
        collapseButton.setText("Collapse");
        collapseButton.setClickable(false);

        Field[] fields = ((Class<?>) type).getDeclaredFields();
        for (Field field : fields) {
            if (Modifier.isPublic(field.getModifiers())) {
                ArgInfo fieldModel = controller.getModel(view.getPaddingLeft() + padding, field.getGenericType());
                modelToFieldMap.put(fieldModel, field);
                fieldModel.createView(field.getName());
                subModels.add(fieldModel);
                views.add(fieldModel.getMainView());
            }
        }
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
    public int getRowsCount() {
        int rows = 1;
        for (ArgInfo model : subModels) {
            rows += model.getRowsCount();
        }
        return rows;
    }

    @Override
    public View addView(View view) {
        if (view == this.view)
            return null;
        View newView = null;
        for (ArgInfo model : subModels) {
            if ((newView = model.addView(view)) != null) {
                return newView;
            }
        }
        return null;
    }

    @Override
    public Object getValue() throws ParseException {
        Object result = null;
        try {
            Constructor constructor = ((Class<?>) type).getConstructor(new Class[0]);
            result = constructor.newInstance();
            for (ArgInfo model : subModels) {
                Field field = modelToFieldMap.get(model);
                field.set(result, model.getValue());
            }
        } catch (NoSuchMethodException e) {
            e.printStackTrace();  //To change body of catch statement use File | Settings | File Templates.
        } catch (InvocationTargetException e) {
            e.printStackTrace();  //To change body of catch statement use File | Settings | File Templates.
        } catch (InstantiationException e) {
            e.printStackTrace();  //To change body of catch statement use File | Settings | File Templates.
        } catch (IllegalAccessException e) {
            e.printStackTrace();  //To change body of catch statement use File | Settings | File Templates.
        }
        return result;
    }

    @Override
    public void setValue(Object value) {
        view.setClickable(true);
        for (ArgInfo model : subModels) {
            try {
                Field field = modelToFieldMap.get(model);
                model.setValue(field.get(value));
            } catch (IllegalAccessException e) {
                e.printStackTrace();  //To change body of catch statement use File | Settings | File Templates.
            }
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
