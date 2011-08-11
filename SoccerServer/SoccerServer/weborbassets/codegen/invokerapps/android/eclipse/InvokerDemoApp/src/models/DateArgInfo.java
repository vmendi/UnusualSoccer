package models;

import android.app.Activity;
import android.view.LayoutInflater;
import android.view.View;
import android.widget.TextView;
import com.example.R;
import controllers.AbstractController;

import java.lang.reflect.Type;
import java.text.DateFormat;
import java.text.ParseException;
import java.text.SimpleDateFormat;
import java.util.Calendar;
import java.util.Date;

/**
 * Model for Date type of data
 * @author Yuri Samsoniuk
 */
public class DateArgInfo extends ArgInfo {
    /**
     * Constructor of the model
     * @param type of data represented by the model
     * @param activity  application activity
     * @param controller handling controller
     * @param padding padding of the main view
     */
    public DateArgInfo(Type type, Activity activity, AbstractController controller, int padding) {
        super(type, activity, controller, padding);
    }

    @Override
    public void createView(String name) {
        LayoutInflater inflater = LayoutInflater.from(activity);
        view = inflater.inflate(R.layout.simple_type_view, null);
        TextView nameView = ((TextView) view.findViewById(R.id.name));
        nameView.setText(name);
        nameView.setPadding(nameView.getPaddingLeft() + padding, nameView.getPaddingTop(),
                nameView.getPaddingRight(), nameView.getPaddingBottom());
        ((TextView) view.findViewById(R.id.type)).setText(((Class) type).getSimpleName());
        view.setOnClickListener(controller.getListener());
    }

    @Override
    public View getMainView() {
        return view;
    }

    @Override
    public Object getValue() throws ParseException {
        String dateFormat = activity.getApplicationContext().getResources().getString(R.string.date_format);
        DateFormat df = new SimpleDateFormat(dateFormat);
        return df.parse(((TextView) view.findViewById(R.id.value)).getText().toString());
    }

    @Override
    public void setValue(Object value) {
        if (value != null) {
            Calendar cal = Calendar.getInstance();
            cal.setTime((Date) value);
            String date_format = activity.getResources().getString(R.string.date_format);
            SimpleDateFormat sdf = new SimpleDateFormat(date_format);
            ((TextView) view.findViewById(R.id.value)).setText(sdf.format(cal.getTime()));
        } else {
            ((TextView) view.findViewById(R.id.value)).setHint(R.string.empty);
        }
        view.findViewById(R.id.value).setClickable(false);
    }
}
