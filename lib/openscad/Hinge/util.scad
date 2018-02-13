function hinge_a_y_gap_offset (l1, l2, gap_epsilon, first) = l1 + (first ? 0:  ((l2 / 2) - (gap_epsilon / 4)));
function hinge_b_y_gap_offset (l1, l2, gap_epsilon, first) = l1 + (l2 / 4) - (gap_epsilon / 4) + (first ? 0 : l2 / 2);

function hinge_a_y_gap_height (l2, gap_epsilon, first) = first ? (l2 / 4 + gap_epsilon / 4) : (l2 / 4 + gap_epsilon / 2);
function hinge_b_y_gap_height (l2, gap_epsilon, first) = hinge_a_y_gap_height(l2, gap_epsilon, !first); // reverse
