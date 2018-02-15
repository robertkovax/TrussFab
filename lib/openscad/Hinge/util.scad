function hinge_b_y_gap (l1, gap_height, gap_epsilon, first_or_second) = l1 + gap_height + first_or_second * (2 * gap_height + gap_epsilon);

function hinge_a_y_gap (l1, gap_height, gap_epsilon, first_or_second) = l1 + first_or_second * ( 2 * gap_height + gap_epsilon);
